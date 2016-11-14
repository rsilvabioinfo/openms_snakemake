# TODO: This needs to be a little more flexible
SAMPLES=["Fecal_1uM_QE1", "Fecal_1uM_QE2", "Fecal_1uM_QE3"]

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

# TODO: need ini files
rule align:
     input:
        featurexml=expand("features/{sample}.featureXML", sample=SAMPLES)
     output:
        featurexml=expand("aligned/{sample}.featureXML", sample=SAMPLES)
     shell:
        "MapAlignerPoseClustering -in {input.featurexml} -out {output.featurexml}"

# TODO: need ini files
rule linker:
     input:
        featurexml=expand("aligned/{sample}.featureXML", sample=SAMPLES)
     output:
        "linked/file.consensusXML"
     shell:
        "FeatureLinkerUnlabeledQT -in {input.featurexml} -out {output}"

rule tabular:
     input:
        "linked/file.consensusXML"
     output:
        "data/table.csv"
     shell:
          "TextExporter -in {input} -out {output}"

# TODO: Need to create rule for creating bucket table