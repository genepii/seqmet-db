#!/usr/bin/env python3
import os
import sys
import argparse

def table_aslist(table, separator):
    table_list = []
    table_temp = [ x.split(separator) for x in open(table, 'r').read().rstrip('\n').replace('\r\n','\n').split('\n') ]
    for i in range(len(table_temp[0])):
        table_list.append([])
    for i in range(len(table_temp)):
        for j in range(len(table_temp[i])):
            table_list[j].append(table_temp[i][j])
    return table_list

parser = argparse.ArgumentParser(description='generate a mutation matrix from a mutation profile file')
debugmode = parser.add_mutually_exclusive_group()
debugmode.add_argument('-v', '--verbose', action='store_true')
debugmode.add_argument('-q', '--quiet', action='store_true')
parser.add_argument('--version', action='version', version='0.0.1')
parser.add_argument('-p', '--profile', help='path to the profile file')
parser.add_argument('-c', '--clade', help='path to the lineage-clade lookup table')
parser.add_argument('-x', '--comment', help='path to the lineage-comment lookup table')
parser.add_argument('-o', '--outfile', help='output files to specified dir', default='./')

if __name__ == '__main__':
    args = parser.parse_args()

#parse lineages and their correspondences in lookup tables
list_profile_lineage = table_aslist(args.profile, '\t')[0][1:]

list_clade_corres = [ [x.split(',')[0], ','.join(x.split(',')[1:])] for x in open(args.clade, 'r').read().replace('\r\n', '\n').rstrip('\n').split('\n')]
list_clade_corres_lineage = [ x[0] for x in list_clade_corres ]
list_clade_corres_clade = [ x[1] for x in list_clade_corres ]
list_comment_corres = [ [x.split(',')[0], ','.join(x.split(',')[1:])] for x in open(args.comment, 'r').read().replace('\r\n', '\n').rstrip('\n').split('\n')]
list_comment_corres_lineage = [ x[0] for x in list_comment_corres ]
list_comment_corres_comment = [ x[1] for x in list_comment_corres ]

#parse mutations, splitting positions considered and actual changes
list_profile_change = table_aslist(args.profile, '\t')[1][1:]
list_profile_base = []
list_profile_acquired = []
for i in range(len(list_profile_change)):
    if list_profile_change[i][0:3] == 'Ins':
        list_profile_base.append(list_profile_change[i].split(':')[0] + ':' + ''.join(i for i in list_profile_change[i].split(':')[1] if i.isdigit()))
        list_profile_acquired.append(''.join(i for i in list_profile_change[i].split(':')[1] if not i.isdigit()))
    else:
        list_profile_base.append(list_profile_change[i][:-1])
        list_profile_acquired.append(list_profile_change[i][-1:])

#find unique lineages and positions
list_profile_lineage_set = list(set(list_profile_lineage))
list_profile_base_set = list(set(list_profile_base))
list_profile_lineage_set.sort()
list_profile_base_set.sort()

#associate lineages with their clade and comment
list_profile_clade = [ list_clade_corres_clade[list_clade_corres_lineage.index(x)] if x in list_clade_corres_lineage else 'missing' for x in list_profile_lineage_set ]
list_profile_comment = [ list_comment_corres_comment[list_comment_corres_lineage.index(x)] if x in list_comment_corres_lineage else 'missing' for x in list_profile_lineage_set]

#create an empty changes list of all positions considered for each lineage, then for each change replace the empty string by the actual for the lineage considered
list_profile_lineage_acquired = [ [ '' for y in list_profile_lineage_set] for x in list_profile_base_set ]

for i in range(len(list_profile_change)):
    loop_profile_lineage_index = list_profile_lineage_set.index(list_profile_lineage[i])
    loop_profile_base_index = list_profile_base_set.index(list_profile_base[i])
    list_profile_lineage_acquired[loop_profile_base_index][loop_profile_lineage_index] = list_profile_acquired[i]

#write the profiles as a matrix
output = open(args.outfile, 'w')
output.write('change\tnt1\tnt2\tnt3\t' + '\t'.join([ list_profile_clade[i] + '_' + list_profile_comment[i] + '_' + list_profile_lineage_set[i] for i in range(len(list_profile_lineage_set)) ]) + '\n')

for i in range(len(list_profile_lineage_acquired)):
    output.write(list_profile_base_set[i] + '\t\t\t\t' + '\t'.join(list_profile_lineage_acquired[i]) + '\n')

output.close()
