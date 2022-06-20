#!/usr/bin/env python3
import os
import sys
import argparse
from datetime import datetime

def table_aslist(table, separator):
    table_list = []
    table_temp = [ x.split(separator) for x in open(table, 'r').read().rstrip('\n').replace('\r\n','\n').split('\n') ]
    for i in range(len(table_temp[0])):
        table_list.append([])
    for i in range(len(table_temp)):
        for j in range(len(table_temp[i])):
            table_list[j].append(table_temp[i][j])
    return table_list

parser = argparse.ArgumentParser(description='generate a validation report from seqmet files')
debugmode = parser.add_mutually_exclusive_group()
debugmode.add_argument('-v', '--verbose', action='store_true')
debugmode.add_argument('-q', '--quiet', action='store_true')
parser.add_argument('--version', action='version', version='0.0.1')
parser.add_argument('-a', '--assignment', help='path to nextclade file or joined nextclade-pangolin file')
parser.add_argument('-c', '--criteria', help='headers to regroup for assignment, given as string separated by comma')
parser.add_argument('-t', '--threshold', type=float, default=0.90, help='retain mutations found at a frequency above this threshold')
parser.add_argument('-o', '--outfile', help='path to output file', default='./')

if __name__ == '__main__':
    args = parser.parse_args()

#parse input file, find headers to use for assignment
print("parse input file", datetime.now())
list_assignment_full = table_aslist(args.assignment, '\t')
list_assignment_headers = [ x[0] for x in list_assignment_full ]
list_assignment_headers_index = [ list_assignment_headers.index(x) for x in args.criteria.split(',') ]

#find the assignment of each entry, potentially using a composite critera
print("find the assignment", datetime.now())
list_assignment = []
list_assignment_temp = []

for i in range(1,len(list_assignment_full[0])):
    for j in range(len(list_assignment_headers_index)):
        list_assignment_temp.append(list_assignment_full[list_assignment_headers_index[j]][i].replace('"', ''))
    list_assignment.append('/'.join(list_assignment_temp))
    list_assignment_temp = []

#list unique assignments
print("list unique assignments", datetime.now())
list_assignment_set = list(set(list_assignment))
list_assignment_set.sort()

#list assignments with the most sequences for each main criteria, useful when multiple secondary criteria exists for a same main criteria
print("list assignments", datetime.now())
list_assignment_set_best = []

for i in range(len(list_assignment_set)):
    loop_assignment_base = list_assignment_set[i].split('/')[0]
    if loop_assignment_base not in [ x.split('/')[0] for x in list_assignment_set_best ]:
        list_assignment_set_best.append(list_assignment_set[i])
    elif list_assignment.count(list_assignment_set[i]) > list_assignment.count(list_assignment_set_best[[ x.split('/')[0] for x in list_assignment_set_best ].index(loop_assignment_base)]):
        list_assignment_set_best[[ x.split('/')[0] for x in list_assignment_set_best ].index(loop_assignment_base)] = list_assignment_set[i]

#parse substitutions and indels to be exploitable
print("parse substitutions", datetime.now())
list_aaSubstitutions = table_aslist(args.assignment, '\t')[26][1:]
list_aaDeletions = table_aslist(args.assignment, '\t')[27][1:]
list_insertions_temp = table_aslist(args.assignment, '\t')[17][1:]
list_insertions = [ ','.join([ 'Ins:' + y.split(':')[0] + y.split(':')[1] for y in x.split(',') if y != '']) for x in list_insertions_temp]

list_profile = []

for i in range(len(list_assignment)):
    for item in [ x for x in list_aaDeletions[i].split(',') if x not in list_profile and x not in ['']]:
        list_profile.append(item)
    for item in [ x for x in list_insertions[i].split(',') if x not in list_profile and x not in [''] and x[:5] != 'Ins:0']:
        list_profile.append(item)
    for item in [ x for x in list_aaSubstitutions[i].split(',') if x not in list_profile and x not in ['']]:
        list_profile.append(item)

#count mutations found for each assignment
print("count mutations", datetime.now())
list_assignment_count = [ [ 0 for y in list_profile] for x in list_assignment_set ]
list_assignment_tot = [ 0 for x in list_assignment_set ]
    
for i in range(len(list_assignment)):
    loop_assignment = list_assignment[i]
    loop_assignment_index = list_assignment_set.index(loop_assignment)
    list_assignment_tot[loop_assignment_index] += 1
    for item in [ x for x in list_aaDeletions[i].split(',') if x not in ['']]:
        loop_profile_index = list_profile.index(item)
        list_assignment_count[loop_assignment_index][loop_profile_index] += 1
    for item in [ x for x in list_insertions[i].split(',') if x not in [''] and x[:5] != 'Ins:0']:
        loop_profile_index = list_profile.index(item)
        list_assignment_count[loop_assignment_index][loop_profile_index] += 1
    for item in [ x for x in list_aaSubstitutions[i].split(',') if x not in ['']]:
        loop_profile_index = list_profile.index(item)
        list_assignment_count[loop_assignment_index][loop_profile_index] += 1

#write mutations and their frequency for each assignment if their frequency is equel or higher to the threshold
#filter assignments considered the best for a given main criteria
print("write mutations", datetime.now())
output = open(args.outfile, 'w')
output.write('clade\tchange\tcount\ttot\tratio\n')

for i in range(len(list_assignment_count)):
    loop_assignment = list_assignment_set[i]
    loop_assignment_index = list_assignment_set.index(loop_assignment)
    print(loop_assignment, datetime.now())
    if loop_assignment in list_assignment_set_best:
        for j in range(len(list_assignment_count[i])):
            loop_profile_index = list_profile.index(list_profile[j])
            loop_assignment_count = list_assignment_count[loop_assignment_index][loop_profile_index]
            loop_assignment_tot = list_assignment_tot[loop_assignment_index]
            if loop_assignment_tot > 0:
                loop_assignment_perc = loop_assignment_count / loop_assignment_tot
            else:
                loop_assignment_perc = 0
            if loop_assignment_perc >= args.threshold:
                output.write(loop_assignment + '\t' + list_profile[j] + '\t' + str(loop_assignment_count) + '\t' + str(loop_assignment_tot) + '\t' + str(loop_assignment_perc) + '\n')

output.close()
