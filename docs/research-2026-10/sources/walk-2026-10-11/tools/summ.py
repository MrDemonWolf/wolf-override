import sys, ast
for line in sys.stdin:
    if line.startswith(('eng-', 'wolf-')) and ' [' in line:
        head, rest = line.split(' [', 1); print(head)
        L = ast.literal_eval('[' + rest)
        d = [x for x in L if 'weights' in x][-1]
        print(' final iter', d['weights'], d['max_abs_residual'], 'sheet scales', [x.get('sheet_scale') for x in L if 'weights' in x])
        for k in d['patch_residual_x']:
            print('   %-8s x %s' % (k, ' '.join('%5.1f' % v for v in d['patch_residual_x'][k])))
            print('   %-8s y %s' % (k, ' '.join('%5.1f' % v for v in d['patch_residual_y'][k])))
        h = L[-1]
        print('   reseat x', h['head_reseat_x']); print('   reseat y', h['head_reseat_y'])
    elif not line.startswith('   '):
        print(line.rstrip()[:200])
