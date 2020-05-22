# -*- coding: utf-8 -*-
"""
Created on Fri May 15 19:35:20 2020

@author: User
"""

#Importações de módulos
import pandas as pd
from datetime import datetime

#Diretório raiz
#diretorio = input('Insira o diretório onde está a planilha fonte:') + '/'
diretorio = 'C:/Users/User/Desktop/Work/Estudos títulos/planilhas_Tesouro/Histórico leilões/'

#Lista de funções
def ajeita_data():
    '''Função que pega a data de hoje e transforma no formato dd/mm/YY
    Parâmetro de entrada:
    Valor de retorno: str'''
    hj = datetime.today()
    ano = str(hj.year)
    mes = '{:02d}'.format(hj.month)
    dia = '{:02d}'.format(hj.day)
    data_ajustada = dia + '/' + mes + '/' + ano
    return data_ajustada

def converter_em_lista(string):
    '''Funcao para converter string em lista
    Parametro de entrada: string
    Valor de retorno: list'''
    string = str(string)
    li = list(string.split(" "))
    return li 

def transforma_data(dados, nomecoluna, formato = '%Y-%m-%d'):
    '''Funcao que formata uma coluna de um dataframe com formato data
    Parâmetro de entrada: DataFrame, str, date
    Valor de retorno: DataFrame'''
    dados[nomecoluna] = pd.to_datetime(dados[nomecoluna], format = formato)
    return dados

def dados_serie_sgs(codigo_series, data_inicial = '01/01/2017', data_final = ajeita_data()):
    '''Funcao que pega o código de n séries e coleta seus valores entre as datas definidas
    Parâmetro de entrada: int, str, str
    Valor de retorno: pandas'''
    codigo_series = converter_em_lista(codigo_series)
    for i in range(len(list(codigo_series))):
        url_sgs = ("http://api.bcb.gov.br/dados/serie/bcdata.sgs." + str(codigo_series[i]) + "/dados?formato=csv&dataInicial=" + data_inicial + "&dataFinal=" + data_final)
        dados_um_codigo = pd.read_csv(url_sgs, sep=';', dtype = 'str')
        dados_um_codigo['valor'] = dados_um_codigo['valor'].str.replace(',', '.')
        dados_um_codigo['valor'] = dados_um_codigo['valor'].astype(float)
        dados_um_codigo = pd.DataFrame(dados_um_codigo)
        dados_um_codigo = dados_um_codigo.rename(columns = {'Index': 'data', 'valor': str(codigo_series[i])})
        if i==0:
            dados_merge = dados_um_codigo
        else:
            dados_merge = dados_merge.merge(dados_um_codigo, how='outer',on='data')
    return dados_merge


def importar_xlsx(nome_arquivo):
    '''Funcao que importa o arquivo xlsx e transforma em dataframe
    Parâmetro de entrada: excel
    Valor de retorno: pandas'''
    arquivo = pd.read_excel(diretorio + nome_arquivo, header = None)
    arquivo = arquivo.drop(arquivo.index[[0,1,2,3,4,5,6,8]])
    arquivo = arquivo.rename(columns = arquivo.iloc[0,:])
    arquivo = arquivo.drop(arquivo.index[[0]])
    return arquivo

def organiza(dados, nomecoluna):
    '''Função que organiza linhas de acordo com ordem de uma coluna
    Parâmetro de entrada: pandas, str
    Valor de retorno: DataFrame'''
    dados = dados.sort_values(by = [nomecoluna])
    return dados

def filt_dados(dados, nome_coluna, condicao):
    '''Funcao que filtra os dados de acordo com determinada condição
    Parâmetro de entrada: DataFrame, str, str
    Valor de retorno: DataFrame'''
    is_condicao = dados[nome_coluna] == condicao
    dados_filtrados = dados[is_condicao]
    return dados_filtrados

#Importação de série com meta selic diária
meta_selic = dados_serie_sgs('432')

#Importação do arquivo excel vindo do site do tesouro nacional
arquivo_importado = input('Insira nome do arquivo excel a ser importado:') + '.xlsx'
titulo = importar_xlsx(arquivo_importado)

#Organizando dados de acordo com data do leilão
titulo = organiza(titulo, 'Data do leilão')

#Formatando datas
titulo = transforma_data(titulo, 'Data do leilão')
titulo = transforma_data(titulo, 'Data de liquidação')
titulo = transforma_data(titulo, 'Data de vencimento')
meta_selic = transforma_data(meta_selic, 'data', '%d/%m/%Y')

#Filtros
#1)Tipo de leilão
titulo = filt_dados(titulo, 'Tipo de leilão', 'Venda')
#2)Volta
titulo = filt_dados(titulo, 'Volta', '1.ª volta')
    
#3)Data de vencimento e inserção da meta SELIC
meta_selic = meta_selic.rename(columns = {'data':'Data do leilão', '432':'Meta SELIC'})

datas_disponiveis = pd.unique(titulo['Data de vencimento']) #usado para filtrar as diferentes datas de vencimento
datas_disponiveis.sort() #Ordenar cronologicamente as datas

nome_datas_disponiveis = pd.DataFrame(pd.unique(titulo['Data de vencimento'])) #usado pra nomear as abas da planilha
nome_datas_disponiveis = organiza(nome_datas_disponiveis, 0)

tipo_titulo = input('Qual o tipo do título? (LTN ou NTN_F): ')
    
for i in range(len(datas_disponiveis)):
    data_vencimento = datas_disponiveis[i]
    aba_titulo = filt_dados(titulo, 'Data de vencimento', data_vencimento)
    aba_titulo = pd.merge(meta_selic, aba_titulo, on = 'Data do leilão')
    aba_titulo['Spread'] = aba_titulo['Taxa média'] - aba_titulo['Meta SELIC']
    data_pro_nome = str(nome_datas_disponiveis.iloc[[i]])[-10:]
    data_pro_nome = data_pro_nome.replace('-','_')
    nome_titulo = tipo_titulo + '_' + str(data_pro_nome)
    nome_aba = nome_titulo[:8]
    exec(nome_titulo + " = aba_titulo")
    writer = diretorio + tipo_titulo + '.xlsx'
    
    if i == 0:
        aba_titulo.to_excel(writer, index = False, sheet_name = nome_aba)
    else:
        with pd.ExcelWriter(writer, mode = 'a') as writer:
            aba_titulo.to_excel(writer, index = False, sheet_name = nome_aba)        
                    
    spread = aba_titulo[['Data do leilão','Data de vencimento', 'Spread']]
    spread = spread.rename(columns = {'Data de vencimento':'Vencimento '+ nome_aba ,'Spread': nome_aba})
    if i == 0:
        spread_merge = spread
    else:
        spread_merge = spread_merge.merge(spread, how='outer',on='Data do leilão')

spread_merge.sort_values(by = 'Data do leilão') #Ordenando cronologicamente datas

with pd.ExcelWriter(writer, mode = 'a') as writer:  
    spread_merge.to_excel(writer, index = False, sheet_name = 'Spreads')




