import glob

files = glob.glob("data/*")
bfiles = list(map(lambda x: os.path.splitext(x)[0], files))
SAMPLES = list(map(lambda x: x.split('/')[1], bfiles))

rule all:
    input:
        "data/metabolomics_table.tsv"

rule file_converter:
    input:
        "data/{sample}.mzXML"
    output:
        "converted_data/{sample}.mzML"
    shell:
        "FileConverter -in {input} -out {output}"

# TODO: will need to have a script to replace the important parameters
# Specifically, we'll need another to rule to automatically tune parameters
# i.e. regression
rule feature_finding:
    input:
        ini="params/featurefindermetabo.ini",
        mzml="converted_data/{sample}.mzML"
    output:
        "features/{sample}.featureXML"
    shell:
        "FeatureFinderMetabo -ini {input.ini} -in {input.mzml} -out {output}"

rule align:
     input:
        alini="params/mapalignerposeclustering.ini",
        featurexml=expand("features/{sample}.featureXML", sample=SAMPLES)
     output:
        featurexml=expand("aligned/{sample}.featureXML", sample=SAMPLES)
     shell:
        "MapAlignerPoseClustering -ini {input.alini} -in {input.featurexml} -out {output.featurexml}"

rule linker:
     input:
        lkini="params/featurelinkerunlabeledqt.ini",
        featurexml=expand("aligned/{sample}.featureXML", sample=SAMPLES)
     output:
        "linked/file.consensusXML"
     shell:
        "FeatureLinkerUnlabeledQT -ini {input.lkini} -in {input.featurexml} -out {output}"

rule tabular:
     input:
        "linked/file.consensusXML"
     output:
        "data/table.csv"
     shell:
       "TextExporter -in {input} -out {output}"

# TODO: test different output tables
rule convert:
	input:
	  "data/table.csv"
	output:
	  "data/metabolomics_table.tsv"
	shell:
	  "python openms2biom.py -i {input} -o {output}"

