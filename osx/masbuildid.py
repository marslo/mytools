#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
Print a Mac App Store app's item id and external version id (aka build id).

The build id is App Store's "software version external identifier"; it lives
in the app's _MASReceipt/receipt (a DER-encoded PKCS#7 file), not Info.plist.
With --compare, also read the store's store_software_version_id from the local
appstoreagent cache and flag stale update states.

USAGE:
    $ python3 ~/Desktop/script/shell/masbuildid.py -c /Applications/*.app ~/Applications/*.app
"""

import argparse
import os
import shutil
import sqlite3
import subprocess
import sys
import tempfile

STORE_DB = os.path.expanduser(
    '~/Library/Caches/com.apple.appstoreagent/storeSystem.db'
)


def _read_len( buf, i ):
    """ decode one DER length starting at i; return ( length, next_index ). """
    n = buf[i]
    i += 1
    if n < 0x80:
        return n, i
    k = n & 0x7f
    return int.from_bytes( buf[i:i + k], 'big' ), i + k


def _parse_set( buf ):
    """ parse the receipt payload SET into { fieldType: rawValue }. """
    if not buf or buf[0] != 0x31:
        return {}
    _, i = _read_len( buf, 1 )
    fields = {}
    while i < len( buf ):
        if buf[i] != 0x30:
            break
        i += 1
        seq_len, i = _read_len( buf, i )
        end = i + seq_len
        i += 1
        l, i = _read_len( buf, i )
        ftype = int.from_bytes( buf[i:i + l], 'big' )
        i += l
        i += 1
        l, i = _read_len( buf, i )
        i += l                                  # skip attribute version
        i += 1
        l, i = _read_len( buf, i )
        fields[ftype] = buf[i:i + l]
        i = end
    return fields


def receipt_fields( app_path ):
    """ return the receipt attribute dict for a .app, or {} if none. """
    receipt = os.path.join( app_path, 'Contents', '_MASReceipt', 'receipt' )
    if not os.path.exists( receipt ):
        return {}
    dump = subprocess.run(
        [ 'openssl', 'asn1parse', '-inform', 'DER', '-in', receipt ],
        capture_output=True, text=True, check=False
    ).stdout
    for line in dump.splitlines():
        if 'OCTET STRING' not in line or '[HEX DUMP]:' not in line:
            continue
        try:
            raw = bytes.fromhex( line.split( '[HEX DUMP]:' )[1].strip() )
        except ValueError:
            continue
        fields = _parse_set( raw )
        if 2 in fields:                         # field 2 == bundle id marker
            return fields
    return {}


def as_str( value ):
    """ decode a UTF8String / IA5String receipt value. """
    if value[:1] in ( b'\x0c', b'\x16' ):
        return value[2:].decode( 'utf-8', 'replace' )
    return None


def as_int( value ):
    """ decode an INTEGER receipt value. """
    if value[:1] == b'\x02':
        return int.from_bytes( value[2:], 'big' )
    return None


def store_version_ids():
    """
    map bundle_id -> ( store_software_version_id, update_state ).

    copy the live db plus its -wal/-shm to a temp dir first so uncommitted
    WAL frames are visible and the in-use cache is never touched.
    """
    if not os.path.exists( STORE_DB ):
        return {}
    tmp = tempfile.mkdtemp( prefix='masbuildid.' )
    try:
        base = os.path.join( tmp, 'storeSystem.db' )
        for suffix in ( '', '-wal', '-shm' ):
            src = STORE_DB + suffix
            if os.path.exists( src ):
                shutil.copy2( src, base + suffix )
        con = sqlite3.connect( base )
        rows = con.execute(
            'SELECT bundle_id, store_software_version_id, update_state '
            'FROM mapi_app_update'
        ).fetchall()
        con.close()
    except ( sqlite3.Error, OSError ):
        return {}
    finally:
        shutil.rmtree( tmp, ignore_errors=True )
    return { b: ( v, s ) for b, v, s in rows }


def report( app_path, store_map, compare ):
    """ print one app's ids; return 0 on success, 1 if not a MAS app. """
    fields = receipt_fields( app_path )
    if not fields:
        print( f'{app_path}: not a Mac App Store app (no receipt)',
               file=sys.stderr )
        return 1
    bundle_id = as_str( fields.get( 2, b'' ) )
    ext_id = as_int( fields.get( 16, b'' ) )
    print( os.path.basename( app_path.rstrip( '/' ) ) )
    print( f'  bundle_id      : {bundle_id}' )
    print( f"  short_version  : {as_str( fields.get( 3, b'' ) )}" )
    print( f"  item_id (adam) : {as_int( fields.get( 1, b'' ) )}" )
    print( f'  ext_version_id : {ext_id}' )
    if compare:
        store_id, state = store_map.get( bundle_id, ( None, None ) )
        if store_id is None:
            note = 'not in local store cache'
        elif store_id == ext_id:
            note = 'up to date'
            if state:
                note += f' (STALE update_state={state} — false badge)'
        else:
            note = f'store={store_id} > installed={ext_id} -> update'
        print( f'  store_build_id : {store_id}  [{note}]' )
    return 0


def main():
    parser = argparse.ArgumentParser(
        description='show a Mac App Store app item id + external version id'
    )
    parser.add_argument( 'apps', nargs='+', metavar='APP',
                         help='path(s) to .app bundle(s)' )
    parser.add_argument( '-c', '--compare', action='store_true',
                         help='compare against the local App Store cache db' )
    args = parser.parse_args()

    store_map = store_version_ids() if args.compare else {}
    rc = 0
    for app in args.apps:
        rc |= report( app, store_map, args.compare )
    return rc


if __name__ == '__main__':
    sys.exit( main() )

# vim:tabstop=4:softtabstop=4:shiftwidth=4:expandtab:filetype=python:
