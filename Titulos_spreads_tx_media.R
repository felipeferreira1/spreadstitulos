#Diret�rio raiz
#diretorio = input('Insira o diret�rio onde est� a planilha fonte:') + '/'
getwd()
setwd("C:\\Users\\User\\Downloads")

#Importa��o de pacotes
library(dplyr)
library(BETS)
library(rio)
library(ggplot2)
library(ggrepel)

#Montando fun��es
para_data <- function(df, nomes_colunas){
  for(i in 1:length(nomes_colunas)){
    df[,nomes_colunas[i]] <- as.Date(df[,nomes_colunas[i]], format = "%d/%m/%Y")
  }
  return(df)
}

para_numero <- function(df, nomes_colunas){
  for(i in 1:length(nomes_colunas)){
    df[,nomes_colunas[i]] <- as.numeric(gsub(",", ".", df[,nomes_colunas[i]], fixed = T))
  }
return(df)
}

#Importa��o de arquivos
#nome_arquivo_ltn <- as.character(readline("Insira nome do arquivo excel da LTN a ser importado:")) %>% paste(".csv", sep = "")
nome_arquivo_ltn <- "hist�rico leil�es LTN.csv"
ltn <- import(nome_arquivo_ltn, skip = 7, encoding = "Latin-1")
ltn <- ltn[-1,]

#nome_arquivo_ntn_f <- as.character(readline("Insira nome do arquivo excel da NTN-F a ser importado:")) %>% paste(".csv", sep = "")
nome_arquivo_ntn_f <- "hist�rico leil�es NTN-F.csv"
ntn_f <- import(nome_arquivo_ntn_f, skip = 7, encoding = "Latin-1")
ntn_f <- ntn_f[-1,]

meta_selic <- BETSget("432")
colnames(meta_selic) <- c("Data", "Meta Selic")

#Mudan�a de colunas para formato de data
nomes_colunas_para_data <- c("Data do leil�o", "Data de liquida��o", "Data de vencimento")
ltn <- para_data(ltn, nomes_colunas_para_data)
ntn_f <- para_data(ntn_f, nomes_colunas_para_data)

#Mudan�a de colunas para formato de numero
nomes_colunas_para_numero <- c("Taxa m�dia", "Taxa de corte")
ltn <- para_numero(ltn, nomes_colunas_para_numero)
ntn_f <- para_numero(ntn_f, nomes_colunas_para_numero)

#Aplicando filtros
ltn <- filter(ltn, `Tipo de leil�o` == "Venda",  Volta == "1.� volta")
ntn_f <- filter(ntn_f, `Tipo de leil�o` == "Venda",  Volta == "1.� volta")

#Fazendo c�lculos
datas_vencimento_ltn <- unique(ltn[,"Data de vencimento"])
datas_vencimento_ntn_f <- unique(ntn_f[,"Data de vencimento"])

ltn <- left_join(ltn, meta_selic, by = c("Data do leil�o" = "Data"))
ntn_f <- left_join(ntn_f, meta_selic, by = c("Data do leil�o" = "Data"))
#ltn$Spreads <- as.numeric(gsub(",", ".", ltn$`Taxa m�dia`, fixed = TRUE)) - as.numeric(ltn$`Meta Selic`)
#ntn_f$Spreads <- as.numeric(gsub(",", ".", ntn_f$`Taxa m�dia`, fixed = TRUE)) - as.numeric(ntn_f$`Meta Selic`)
ltn$Spreads <- ltn$`Taxa m�dia` - ltn$`Meta Selic`
ntn_f$Spreads <- ntn_f$`Taxa m�dia` - ntn_f$`Meta Selic`
lista_de_nomes_ltn <- vector()
lista_de_nomes_ntn_f <- vector()

#Exporta��o de arquivos
  #LTN
for(i in 1:length(datas_vencimento_ltn)){
  filtrado <- filter(ltn, `Data de vencimento` == datas_vencimento_ltn[i]) %>% arrange(`Data do leil�o`)
  nome_aba <- paste("LTN", datas_vencimento_ltn[i], sep = "-") %>% gsub(x = , pattern = "-", replacement = "_")
  lista_de_nomes_ltn[i] <- nome_aba
  assign(nome_aba, filtrado)
  if(i == 1){
    export(filtrado, file = "Titulos_spreads_taxas.xlsx", sheetName = nome_aba)
  }
  else{
    export(filtrado, file = "Titulos_spreads_taxas.xlsx", which = nome_aba)
  }
}

  #NTN-F
for(i in 1:length(datas_vencimento_ntn_f)){
  filtrado <- filter(ntn_f, `Data de vencimento` == datas_vencimento_ntn_f[i])
  nome_aba <- paste("NTN_F", datas_vencimento_ntn_f[i], sep = "-") %>% gsub(x = , pattern = "-", replacement = "_")
  lista_de_nomes_ntn_f[i] <- nome_aba
  assign(nome_aba, filtrado)
  if(i == 1){
    export(filtrado, file = "Titulos_spreads_taxas.xlsx", which = nome_aba)
    }
  else{
    export(filtrado, file = "Titulos_spreads_taxas.xlsx", which = nome_aba)
  }
}

#Gr�ficos

titulos_ltn <- ltn
titulos_ltn$`Data de vencimento` <- paste("LTN", titulos_ltn$`Data de vencimento`)
titulos_ntn_f <- ntn_f
titulos_ntn_f$`Data de vencimento` <- paste("NTN-F", titulos_ntn_f$`Data de vencimento`)
titulos <- rbind(titulos_ltn, titulos_ntn_f)

graf1 <- ggplot(ltn, aes(x = `Data do leil�o`, y = `Taxa m�dia`, group = `Data de vencimento`, colour = factor(`Data de vencimento`))) + 
  geom_line(size = 1.5) + theme(legend.position = "bottom") + scale_x_date(date_breaks = "1 month", date_labels = "%b/%Y", ) + 
  theme(axis.text.x = element_text(angle = 90, hjust = 1)) + 
  labs(x = "Data do leil�o", y = "% ao ano", title = "Taxa m�dia por LTN, data do leil�o e data do vencimento", colour = "Data de vencimento")

graf2 <- ggplot(ltn, aes(x = `Data do leil�o`, y = Spreads, group = `Data de vencimento`, colour = factor(`Data de vencimento`))) + 
  geom_line(size = 1.5) + theme(legend.position = "bottom") + scale_x_date(date_breaks = "1 month", date_labels = "%b/%Y", ) + 
  theme(axis.text.x = element_text(angle = 90, hjust = 1)) +
  labs(x = "Data do leil�o", y = "% ao ano", title = "Spreads sobre meta Selic por LTN, data do leil�o e data do vencimento", colour = "Data de vencimento")

graf3 <- ggplot(ntn_f, aes(x = `Data do leil�o`, y = `Taxa m�dia`, group = `Data de vencimento`, colour = factor(`Data de vencimento`))) + 
  geom_line(size = 1.5) + theme(legend.position = "bottom") + scale_x_date(date_breaks = "1 month", date_labels = "%b/%Y", ) + 
  theme(axis.text.x = element_text(angle = 90, hjust = 1)) +
  labs(x = "Data do leil�o", y = "% ao ano", title = "Taxa m�dia por NTN-F, data do leil�o e data do vencimento", colour = "Data de vencimento")

graf4 <- ggplot(ntn_f, aes(x = `Data do leil�o`, y = Spreads, group = `Data de vencimento`, colour = factor(`Data de vencimento`))) + 
  geom_line(size = 1.5) + theme(legend.position = "bottom") + scale_x_date(date_breaks = "1 month", date_labels = "%b/%Y", ) + 
  theme(axis.text.x = element_text(angle = 90, hjust = 1)) +
  labs(x = "Data do leil�o", y = "% ao ano", title = "Spreads sobre meta Selic por NTN-F, data do leil�o e data do vencimento", colour = "Data de vencimento")


graf5 <- ggplot(titulos, aes(x = `Data do leil�o`, y = `Taxa m�dia`, group = `Data de vencimento`, colour = factor(`Data de vencimento`))) +
  geom_line(size = 1.5) + theme_minimal() + theme(legend.position = "bottom") + scale_x_date(date_breaks = "1 month", date_labels = "%b/%Y", ) + 
  theme(axis.text.x = element_text(angle = 90, hjust = 1)) + scale_y_continuous(breaks = seq(-2,10,0.5)) + 
  labs(x = "Data do leil�o", y = "% ao ano", title = "Taxa m�dia por t�tulo, data do leil�o e data do vencimento", colour = "Data de vencimento")

graf6 <- ggplot(titulos, aes(x = `Data do leil�o`, y = Spreads, group = `Data de vencimento`, colour = factor(`Data de vencimento`), label = round(Spreads, 2))) + 
  geom_line(size = 1.5) + theme(legend.position = "bottom") + scale_x_date(date_breaks = "1 month", date_labels = "%b/%Y", ) + 
  theme(axis.text.x = element_text(angle = 90, hjust = 1)) + scale_y_continuous(breaks = seq(-2,10,1)) +
  labs(x = "Data do leil�o", y = "% ao ano", title = "Spreads sobre meta Selic por t�tulo, data do leil�o e data do vencimento", colour = "Data de vencimento")

ggsave("graf1.png", graf1)
ggsave("graf2.png", graf2)
ggsave("graf3.png", graf3)
ggsave("graf4.png", graf4)
ggsave("graf5.png", graf5)
ggsave("graf6.png", graf6)


graficos <- function(df, titulo){
  ggplot(df, aes(x = `Data do leil�o`, y = Spreads, group = `Data de vencimento`,  label = round(Spreads, 2))) + 
    geom_line(size = 1.5) + theme_minimal() + theme(legend.position = "none")+ scale_x_date(date_breaks = "1 month", date_labels = "%b/%Y", ) + 
    theme(axis.text.x = element_text(angle = 90, hjust = 1)) + geom_label_repel() + scale_y_continuous(breaks = seq(-2,10,1)) +
    labs(x = "Data do leil�o", y = "% ao ano", title = titulo, colour = "Data de vencimento")
}

for(i in 1:length(lista_de_nomes_ltn)){
  grafico <- graficos(get(lista_de_nomes_ltn[i]), as.character(lista_de_nomes_ltn[i]))
  nome_arquivo <- paste("grafico", lista_de_nomes_ltn[i], sep = "_")
  assign(nome_arquivo,grafico)
  nome_arquivo <- paste(nome_arquivo, ".png", sep = "")
  ggsave(nome_arquivo, grafico)
}
