process filter_fasta {

    // filter fasta sequences according to quality criteria
    label 'dbkit'
    storeDir params.result
    tag { fastaName }
    beforeScript 'ulimit -Ss unlimited'

    when:
    params.filter_fasta.todo == 1

    input:
    tuple(path(ref), path(fasta))
    
    output:
    tuple(val(refName), path("${refName}_${fastaName}_filtered.fasta"))
    
    script:
    refName = (ref =~ /(.+)\.(.+)/)[0][1]
    fastaName = (fasta =~ /(.+)\.(.+)/)[0][1]
    """
    #!/bin/bash
    export TMPDIR=${params.tmp}
    REFLENGTH="\$(cat ${ref} | tr -d '\\015' | tr -d '\\n' | wc -c)"

    python3 ${params.nfpath}/script/filter_fasta.py --threads $task.cpus --input ${fasta} --output "${refName}_${fastaName}_filtered.fasta" --mincoverage ${params.filter_fasta["mincoverage"]} --reflength \${REFLENGTH}

    """
}

process gentsv_nextclade {

    // generate a nextclade report for a given fasta file
    label 'nextclade'
    storeDir params.result
    tag { fastaName }
    beforeScript 'ulimit -Ss unlimited'

    when:
    params.gentsv_nextclade.todo == 1

    input:
    tuple(val(refName), path(fasta), val(dataset))
    
    output:
    tuple(val(fastaName), path("${fastaName}_nextclade.tsv"))
    
    script:
    memory = (task.memory =~ /([^\ ]+)(.+)/)[0][1]
    fastaName = (fasta =~ /(.+)\.(.+)/)[0][1]
    """
    #!/bin/bash
    export TMPDIR=${params.tmp}
    
    nextclade run \
        -j $task.cpus \
        --input-dataset $dataset \
        --include-reference --in-order --input-fasta ${fasta} --output-tsv "${fastaName}_nextclade.tsv"
    """
}

process gentsv_pangolin {

    // generate a pangolin report for a given fasta file
    label 'pangolin'
    storeDir params.result
    tag { fastaName }
    beforeScript 'ulimit -Ss unlimited'

    when:
    params.gentsv_pangolin.todo == 1

    input:
    tuple(val(refName), path(fasta))
    
    output:
    tuple(val(fastaName), path("${fastaName}_pangolin.csv"))
    
    script:
    memory = (task.memory =~ /([^\ ]+)(.+)/)[0][1]
    fastaName = (fasta =~ /(.+)\.(.+)/)[0][1]
    """
    #!/bin/bash
    export TMPDIR=${params.tmp}
 
    pangolin ${fasta} \
        --outfile "${fastaName}_pangolin.csv" \
        --use-assignment-cache \
        --assignment-cache ${params.gentsv_pangolin["usher_assignments"]} \
        --threads $task.cpus
    """
}

process join_assignment {

    // join csv and tsv files
    label 'dbkit'
    storeDir params.result
    tag { fastaName }

    when:
    params.join_assignment.todo == 1

    input:
    tuple(val(fastaName), path(nextclade), path(pangolin))
    
    output:
    tuple(val(fastaName), path("${fastaName}_assignment.tsv"))
    
    script:
    """
    #!/bin/bash
    export TMPDIR=${params.tmp}

    python3 ${params.nfpath}/script/join_table.py --nextclade ${nextclade} --pangolin ${pangolin} --output "${fastaName}_assignment.tsv"

    """
}

process filter_assignment {

    // filter assignments according to quality criteria
    label 'dbkit'
    storeDir params.result
    tag { fastaName }

    when:
    params.filter_assignment.todo == 1

    input:
    tuple(val(fastaName), path(assignment))
    
    output:
    tuple val(fastaName), path("${fastaName}_id-lineage.csv"), emit: idlineage
    tuple val(fastaName), path("${fastaName}_lineage.txt"), emit: lineage
    tuple val(fastaName), path("${fastaName}_id-lineage_downsample.csv"), emit: downsample
    tuple val(refName), path("${fastaName}_id_downsample.txt"), emit: idlist
    
    script:
    refName = (fastaName =~ /([^\_]+)(.+)/)[0][1]
    """
    #!/bin/bash
    export TMPDIR=${params.tmp}

    awk 'BEGIN {FS="\t"; OFS=","}; \$5=="good" && \$38=="good" && \$42=="good" && \$47=="good" && \$51=="good" && \$58=="good" && \$62=="good" && \$66==0.0 {print \$1,\$65}' ${assignment} > "${fastaName}_id-lineage.csv"
    cut -d',' -f 2 "${fastaName}_id-lineage.csv" | sort | uniq -c | awk '\$1>=${params.filter_assignment["minseq"]} {print \$2}' > "${fastaName}_lineage_temp.txt"
    cat "${fastaName}_lineage_temp.txt" ${params.filter_assignment["added_lineage"]} | sort | uniq > "${fastaName}_lineage.txt"
    shuf --random-source=<(yes 100) "${fastaName}_id-lineage.csv" > "${fastaName}_id-lineage_shuffled.csv"
    for lineage in \$(cat "${fastaName}_lineage.txt"); do awk -v lineage="\${lineage}" 'BEGIN {FS=","}; \$2==lineage && N<${params.filter_assignment["downsample"]} {++N; print \$0}' "${fastaName}_id-lineage_shuffled.csv" >> "${fastaName}_id-lineage_downsample.csv"; done;
    cut -d',' -f 1 "${fastaName}_id-lineage_downsample.csv" > "${fastaName}_id_downsample.txt"

    """
}

process downsample_fasta {

    // filter fasta according to an idlist
    label 'dbkit'
    storeDir params.result
    tag { fastaName }

    when:
    params.filter_assignment.todo == 1

    input:
    tuple(val(refName), path(fasta), path(idlist))
    
    output:
    tuple val(fastaName), path("${fastaName}_downsample.fasta"), emit: fasta
    
    script:
    fastaName = (fasta =~ /(.+)\.(.+)/)[0][1]
    """
    #!/bin/bash
    export TMPDIR=${params.tmp}

    seqkit grep -w 0 -n -f ${idlist} ${fasta} -o "${fastaName}_downsample.fasta"

    """
}

process assign_fasta {

    // sort fasta sequences according to their lineage
    label 'dbkit'
    storeDir params.result
    tag { fastaName }

    when:
    params.assign_fasta.todo == 1

    input:
    tuple(val(fastaName), path(fasta), path(idlineage))
    
    output:
    path("lineages/*")
    
    script:
    fastaName = (fasta =~ /(.+)\.(.+)/)[0][1]
    """
    #!/bin/bash
    export TMPDIR=${params.tmp}
    mkdir -p lineages

    for lineage in \$(cut -d',' -f 2 ${idlineage} | sort | uniq); do grep ",\${lineage}\$" ${idlineage} | cut -d',' -f 1 > id-lineage.txt; seqkit grep -w 0 -n -f id-lineage.txt ${fasta} >> "lineages/\${lineage}.fna"; done;

    """
}

process map_minimap2 {

    // map fasta sequences on a chosen reference
    label 'varcall'
    storeDir params.result
    tag { sampleId }

    when:
    params.map_minimap2.todo == 1

    input:
    tuple(path(fasta), path(ref))
    
    output:
    tuple val(sampleId), path("minimap2/${ref.simpleName}/${sampleId}.bam"), path("minimap2/${ref.simpleName}/${sampleId}.bam.bai"), path("ref/${ref.simpleName}.fna"), emit : bam
    
    script:
    sampleId = (fasta =~ /(.+)\.(.+)/)[0][1]
    """
    #!/bin/bash
    export TMPDIR=${params.tmp}
    mkdir -p "minimap2/${ref.simpleName}" ref

    minimap2 -t $task.cpus -a -x asm20 --sam-hit-only --secondary=no --score-N=0 ${ref} ${fasta} | \
    samtools view --threads $task.cpus -b - | \
    samtools sort --threads $task.cpus -o "minimap2/${ref.simpleName}/${sampleId}.bam"
    samtools index "minimap2/${ref.simpleName}/${sampleId}.bam"

    cp "${ref}" "ref/${ref.simpleName}.fna"
    """
}

process callvar_freebayes {

    // call and filter variants based on a given set of quality criteria

    label 'varcall'
    storeDir (params.result)
    tag { sampleId }

    when:
    params.callvar_freebayes.todo == 1

    input:
    tuple(val(sampleId), path(bam), path(bai), path(ref))
    
    output:
    tuple val(refName), path("vcf/${ref.simpleName}/${sampleId}.vcf"), emit : vcf
    
    script:
    refName = (ref =~ /(.+)\.(.+)/)[0][1]
    """
    #!/bin/bash
    export TMPDIR=${params.tmp}

    mkdir -p vcf/${ref.simpleName}/ work/${ref.simpleName}/ ref/
    perl -i.bkp -pe 's/\\r\$//' ${ref}

    freebayes --theta ${params.callvar_freebayes["theta"]} --ploidy ${params.callvar_freebayes["ploidy"]} --report-all-haplotype-alleles --pooled-continuous --use-best-n-alleles ${params.callvar_freebayes["use-best-n-alleles"]} --allele-balance-priors-off --haplotype-length ${params.callvar_freebayes["haplotype_length"]} --use-duplicate-reads --genotyping-max-iterations ${params.callvar_freebayes["genotyping-max-iterations"]} --genotyping-max-banddepth ${params.callvar_freebayes["genotyping-max-banddepth"]} --min-mapping-quality ${params.callvar_freebayes["min_mapping_quality"]} --min-base-quality ${params.callvar_freebayes["min_base_quality"]} -F 0.01 -C ${params.callvar_freebayes["min_var_depth"]} --min-coverage ${params.callvar_freebayes["min_depth"]} --f ${ref} -b ${bam} > "work/${ref.simpleName}/${sampleId}.vcf"

    vt decompose -s "work/${ref.simpleName}/${sampleId}.vcf" -o "work/${ref.simpleName}/${sampleId}_decomposed.vcf"
    python2.7 ${params.nfpath}/script/recalc_fbvcf.py -i "work/${ref.simpleName}/${sampleId}_decomposed.vcf" -o "work/${ref.simpleName}/${sampleId}_recalc.vcf" -n 0.0 -x 1.0 -t snp,del,ins,mnp,complex
    bcftools filter -i '${params.callvar_freebayes["bcftools_filter"]}' "work/${ref.simpleName}/${sampleId}_recalc.vcf" > "work/${ref.simpleName}/${sampleId}_filtered.vcf"
    vt normalize "work/${ref.simpleName}/${sampleId}_filtered.vcf" -r ${ref} -o "vcf/${ref.simpleName}/${sampleId}.vcf"

    cp ${ref} "ref/${ref.simpleName}.fna"
    rm -rf work
    """
}

process gentsv_mutprofile {

    // generate a tsv file listing all substitutions/indels reported by nextclade for each clade/lineage

    label 'varcall'
    storeDir (params.result)
    tag { fastaName }

    when:
    params.gentsv_mutprofile.todo == 1

    input:
    tuple(val(fastaName), path(assignment))
    
    output:
    tuple val(fastaName), path("${fastaName}_mutprofile.tsv"), emit : tsv
    
    script:
    """
    #!/bin/bash
    export TMPDIR=${params.tmp}

    python ${params.nfpath}/script/gentsv_mutprofile.py -t 0.05 -a $assignment -c ${params.gentsv_mutprofile["header"]} -o "${fastaName}_mutprofile.tsv"

    """
}

process gentsv_mutmatrix {

    // generate a tsv file listing all substitutions reported by nextclade for each clade/lineage

    label 'varcall'
    storeDir (params.result)
    tag { fastaName }

    when:
    params.gentsv_mutmatrix.todo == 1

    input:
    tuple(val(fastaName), path(mutprofile))
    
    output:
    tuple val(fastaName), path("${fastaName}_mutmatrix.tsv"), emit : tsv
    
    script:
    """
    #!/bin/bash
    export TMPDIR=${params.tmp}

    python ${params.nfpath}/script/gentsv_mutmatrix.py -c ${params.gentsv_mutmatrix["lineage-clade"]} -x ${params.gentsv_mutmatrix["lineage-comment"]} -p $mutprofile -o "${fastaName}_mutmatrix.tsv"

    """
}
