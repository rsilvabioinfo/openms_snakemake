import argparse
import re
import pandas as pd
parser = argparse.ArgumentParser(description='Convert from OpenMS format to qiime')
parser.add_argument('-i', '--inp', type=str, help='Input file name')
parser.add_argument('-o', '--out', type=str, help='Output file name')

args = parser.parse_args()
inp = args.inp
out = args.out

# read table to locate the labels
df = pd.read_csv(inp,  sep=' ', header=None)

# Find file name associated to featureXML, to use as sample ID
matching0 = [s for s in list(df[0]) if "featureXML" in s]

# Locate the row where features start
matching = [s for s in range(len(list(df[0]))) if "CONSENSUS" in list(df[0])[s]]

for i in range(len(matching0)):
    # This pattern matching assumes that the featureXML files are inside one directory,
    # have to check consistence for other outputs
    matching0[i] = re.sub('.featureXML', '', matching0[i].split('\t')[2].split('/')[1])

# Read the features from starting point
df2 = pd.read_csv(inp,  sep='\t',  skiprows=range(matching[2]), header=None)

# Assign column names
cnames = list(df.loc[matching[0]])[0].split('\t')
df2.columns = cnames

# Locate the position of the relevant data
str = ['rt_cf', 'mz_cf','quality_cf', 'intensity']
matching2 = [s for s in range(len(cnames)) if any(x in cnames[s] for x in str)]
df2 = df2[matching2]

# Filter low quality feature values - Have to check the utility of this filter
matching3 = [s for s in range(len(list(df2['quality_cf']))) if list(df2['quality_cf'])[s] > 0]
df2 = df2.loc[matching3]

# Take out unused columns
df2.drop(['intensity_cf', 'quality_cf'], inplace=True, axis=1)

# Add sample names to columns
cnames2 = matching0 
cnames2.insert(0, 'rt_cf')
cnames2.insert(1, 'mz_cf')
df2.columns = cnames2

# Add mz and rt as row names
rname = []
for i in range(df2.shape[0]):
    n1 = (list(df2['mz_cf'])[i])
    n2 = (list(df2['rt_cf'])[i])
    s1 = "%8.4f" % n1
    s2 = "%8.4f" % n2
    s = s1 + '_' + s2
    rname.append(s)

# Transpose just to rename
df2 = df2.T
df2.columns = rname

df2 = df2.T
df.index.name = '#OTU ID'

# Replace nan by 0 and save
df2 = df2.fillna(value=0)
df2.drop(['rt_cf', 'mz_cf'], inplace=True, axis=1)
df2.to_csv(out, sep='\t', index_label='#OTU ID')
