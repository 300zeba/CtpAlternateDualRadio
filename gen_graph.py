import sys

file_name = sys.argv[1]

file = open(file_name,"r")

nodes = []
radios = []
for i in range(101):
    nodes.append(1000)
    radios.append(3)

for line in file:
    linha = line.split()
    if len(linha) >= 3:
        if linha[1] == 'CURRENT_DAD':
            nodes[int(linha[0])] = int(linha[2])
        elif linha[1] == 'SEND_RADIO':
            radios[int(linha[0])] = int(linha[2])

string = file_name.split("_")
str = string[1].split(".")

out_file_name = str[0] + '.gv'

out = open(out_file_name,"w")

out.write('graph {0}'.format(str[0]) + ' {\n')



for i in range(1,101):
    if nodes[i] != 1000 and radios[i] != 3:
        print(nodes[i], radios[i])
        out.write('{0} -- '.format(i) + '{0}'.format(nodes[i]))
        if radios[i] == 1:
            out.write(' [color=blue];\n')
        else:
            out.write(' [color=red];\n')


out.write('}')

out.close()
file.close()
