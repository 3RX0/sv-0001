# Assignment:
## UNIX - je třeba dodat celé příkazy včetně všech parametrů:
1. Jak lze vypsat všechny řádky z jakéhokoli souboru, kde se nacházejí pravě dvě pomlčky za sebou na jedné řádce.
2. Jak lze vypsat seznam všech souborů v domovském adresáři, které byly změněné během  posledních 10 hodin.
3. Mějme textový soubor typu csv, který obsahuje libovolný počet řádků (každý má dva  sloupce) a kde oddělovačem sloupců je středník. Jak prohodit oba sloupce? (pro  jednoduchost každý sloupec obsahuje pouze jednoslovné alfanumerické řetězce .  
## Ansible + RabbitMQ  
   Použijte nějaký trial cloudové služby pro deployment (o cloud zde v tuto chvíli vůbec nejde).
1. Deployment RabbitMQ pomocí ansible (stačí když bude dostupný pouze na cloudové  interní adrese).
2. Vytvořte v RabbitMQ několik (alespoň 3) queues (na jejich konfiguraci nezáleží, nebude se  přes ně nic posílat ).
3. Napište script pre linux (python nebo shell) který se dotáže RabbitMQ na seznam všech  queues a vypíše z nich vždy jméno fronty a typ queue.
4. Při spuštění scriptu z předchozího bodu zachyťte tcpdumpem komunikaci mezi skriptem a  RabbitMQ do binárního souboru, celé znění příkazu tcpdump rovněž přiložte.  
   Všechny zdrojové kódy uložte do gitu a zveřejněte na GitHubu. Příkazy ze sekce UNIX a  příkaz z bodu 4 v sekci Ansible+RabbitMQ napište do README souboru a přidejte na GitHub.  Všechny případné další kroky prosím rovněž zdokumentujte. 



# Solution:
## UNIX
**1.** 

V zadání vnímám jistou ambivalenci definice

Pro řešení "právě dvě pomlčky za sebou na jedné řádce" (a ne tři pomlčky a ne jedna pomlčka kdekoliv na řádce)

`grep "\-\-" ./UNIX/testData`

Pro řešení "právě dvě pomlčky za sebou na jedné řádce" (tedy nic jiného):

`grep "^\-\-$" ./UNIX/testData`

Pro elegantnější řešení s využitím regular expressions

`grep -E "\-{2}" ./UNIX/testData`

Kde:
  - "`-E`" parametr pro využití extended regular expressions 

**2.** 

`find ~/ -mmin -600`

Kde: 
 - "`-mmin`" je parametr k nastavení modified time v minutách

**3.** 

Testovací data pro příkaz [zde](https://github.com/3RX0/sv-0001/tree/main/UNIX)

`awk -F \; '{ print $2 ";" $1 }' ./UNIX/testCsvData.csv > ./UNIX/testCsvDataSwitched.csv`

Kde:
 - "`-F`" je parametr nastavující oddělovač pro input $1..$n

## ANSIBLE + RABBITMQ
**1.,2.**

Ansible playbook vytváří VM v GCP na které pomocí dvou rolí instaluje docker a docker-compose a následně provede deployment a základní konfiguraci RabbitMQ s vytvořením front.

Ansible playbook [zde](https://github.com/3RX0/sv-0001/tree/main/ANSIBLE)

- Start with `ansible-playbook main.yml -u sa_113675051069048240838`
  - Note: GCP Service account file.json není přiložen !!! 


**3.,4,**

V rámci scriptu listmq.sh dojde k dotazu na listování front na RabbitMQ API, výstup je pársován nástrojem `jq` pro získání požadovaných dat a zároveň jsou odchyceny packety a zapsány v binárním formátu do složky `./packet-capture` dle data a času spuštění.

Script [zde](https://github.com/3RX0/sv-0001/blob/main/listmq.sh)

- Start with **`listmq.sh -h`**

```
USAGE: listmq.sh [OPTION]
Options:
  -h Print help
  -u RabbitMQ username [admin]
  -p RabbitMQ password [admin]
  -H RabbitMQ hostname or IP [localhost]
  -P RabbitMQ port [15672]

Packet capture with tcpdump runs during RabbitMQ API call execution saving binary capture to ${TCPD_OUTPUT_PATH}
```

Výstupy z tcpdump [zde](https://github.com/3RX0/sv-0001/tree/main/packet-capture)

Příkaz tcp dump spouštěný a terminováný v rámci listmq.sh scriptu:
```
tcpdump -uN host ${RBT_HOST} and port ${RBT_PORT} -w ${TCPD_OUTPUT_PATH}/${TCPD_OUTPUT_FILE} > /dev/null 2>&1 &
```
```
Pozn: 
  Params:
    -U Will cause output to be ``packet-buffered'',
       so that the output is written to stdout at the end of each packet rather than at the end of each line.
    -w Write raw packets to binary file.
    -n No IP/Hostname translations
  Filters:
    host - preset host to be rabbitmq server (from -H flag on script exec)
    port - preset port to be rabbitmq API port (from -P flag on script exec)
  
  "> /dev/null 2>&1"  Redirect remaining output to /dev/null to have clean json output from API call
  
  "&" Runs command on backgroud for script to be able to continue with execution
```