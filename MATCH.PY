#!/usr/bin/env python3
"""DM6000 byte-exact matcher. Run after each compile.
Usage: python3 MATCH.PY [--verbose] [--check ADDR]
"""
import struct, sys
from capstone import Cs, CS_ARCH_X86, CS_MODE_16

ORIG_EXE = '/home/claude/olms2k/OLMS2001.EXE'
OUR_EXE  = 'OLMS2001.EXE'
DM_START = 0x24050
DM_END   = 0x2C8D9
DM_CS    = 0x1E60
DM_FILE  = 0x245F0

cs = Cs(CS_ARCH_X86, CS_MODE_16)

def find_funcs(data, start, end):
    funcs = []
    p = start
    while p < end - 3:
        if data[p]==0x55 and data[p+1]==0x89 and data[p+2]==0xE5:
            funcs.append(p); p += 3
        else: p += 1
    for p in range(start, end-9):
        if (data[p]==0xB4 and data[p+2]==0x8B and data[p+3]==0x16
            and data[p+6]==0xCD and data[p+7]==0x14
            and data[p+8] in (0xC3, 0xCB)):
            if p not in funcs: funcs.append(p)
    return sorted(funcs)

def find_end(data, start, all_funcs, limit):
    idx = all_funcs.index(start) if start in all_funcs else -1
    bound = all_funcs[idx+1] if idx>=0 and idx+1<len(all_funcs) else limit
    if data[start]==0xB4 and data[start+6]==0xCD: return start+9
    for inst in cs.disasm(data[start:min(start+3000, bound)], start):
        if inst.mnemonic in ('retf','ret'): return inst.address + inst.size
    return bound

def get_mnemonics(data, start, end):
    return [i.mnemonic for i in cs.disasm(data[start:end], start)]

def main():
    verbose = '--verbose' in sys.argv or '-v' in sys.argv
    check_addr = None
    if '--check' in sys.argv:
        idx = sys.argv.index('--check')
        check_addr = int(sys.argv[idx+1], 0)

    with open(ORIG_EXE, 'rb') as f: orig = f.read()
    with open(OUR_EXE, 'rb') as f: ours = f.read()

    of = find_funcs(orig, DM_START, DM_END)
    oh = struct.unpack_from('<H', ours, 8)[0] * 16
    uf = find_funcs(ours, oh, len(ours))

    match_count = 0; match_bytes = 0; total_bytes = 0
    results = []  # (status, diffs, orig_addr, orig_size, our_addr, our_size)

    for o in sorted(of):
        oe = find_end(orig, o, of, DM_END); sz = oe - o
        total_bytes += sz
        om = get_mnemonics(orig, o, oe)

        best_d = 999; best_u = None; best_us = 0
        for u in uf:
            ue = find_end(ours, u, uf, len(ours)); us = ue - u
            if abs(us - sz) > max(sz * 0.3, 10): continue
            um = get_mnemonics(ours, u, ue)
            if len(um) == len(om):
                d = sum(1 for a,b in zip(om, um) if a != b)
                if d < best_d: best_d = d; best_u = u; best_us = us

        if best_d == 0:
            status = 'MATCH'; match_count += 1; match_bytes += sz
        elif best_d <= 8: status = 'NEAR'
        elif best_d < 999: status = 'FAR'
        else: status = 'NONE'; best_d = -1

        results.append((status, best_d, o, sz, best_u, best_us))

    # Print summary
    cats = {}
    for r in results:
        cats.setdefault(r[0], []).append(r)

    print(f"=== DM6000 MATCH REPORT ===")
    print(f"Matched: {match_count}/{len(of)} ({match_bytes}/{total_bytes}B = {match_bytes*100//total_bytes}%)")
    for cat in ['MATCH','NEAR','FAR','NONE']:
        items = cats.get(cat, [])
        tb = sum(r[3] for r in items)
        print(f"  {cat:5s}: {len(items):3d} functions, {tb:6d}B")

    if verbose:
        print(f"\nAll functions:")
        for status, diffs, o, sz, bu, bus in results:
            d_str = f"{diffs:3d}d" if diffs >= 0 else " n/a"
            print(f"  {status:5s} {d_str}  {o:#07x} ({sz:5d}B)")

    if check_addr:
        for status, diffs, o, sz, bu, bus in results:
            if o == check_addr:
                print(f"\n=== {check_addr:#07x} ({sz}B): {status}, {diffs} diffs ===")
                if bu:
                    oe = find_end(orig, o, of, DM_END)
                    ue = find_end(ours, bu, uf, len(ours))
                    oi = list(cs.disasm(orig[o:oe], o))
                    ui = list(cs.disasm(ours[bu:ue], bu))
                    for idx in range(max(len(oi), len(ui))):
                        a = oi[idx] if idx < len(oi) else None
                        b = ui[idx] if idx < len(ui) else None
                        mark = ""
                        if a and b and a.mnemonic != b.mnemonic: mark = " ***"
                        elif (a is None) != (b is None): mark = " ***"
                        ao = f"{a.bytes.hex():12s} {a.mnemonic:6s} {a.op_str[:22]}" if a else "---"
                        bo = f"{b.bytes.hex():12s} {b.mnemonic:6s} {b.op_str[:22]}" if b else "---"
                        print(f"  [{idx:2d}] {ao:42s} | {bo}{mark}")
                break

    # Check regressions against STATUS.TXT if it exists
    import os
    if os.path.exists('STATUS.TXT'):
        with open('STATUS.TXT') as f:
            prev_matched = set()
            for line in f:
                if line.strip().startswith('MATCH'):
                    parts = line.split()
                    for p in parts:
                        if p.startswith('0x'):
                            try: prev_matched.add(int(p, 16))
                            except: pass
        cur_matched = {r[2] for r in results if r[0] == 'MATCH'}
        gained = cur_matched - prev_matched
        lost = prev_matched - cur_matched
        if gained: print(f"\nNEW MATCHES: {[f'{a:#07x}' for a in sorted(gained)]}")
        if lost: print(f"REGRESSIONS: {[f'{a:#07x}' for a in sorted(lost)]}")

if __name__ == '__main__':
    main()
