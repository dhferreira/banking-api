# do migrations if needed
bin/banking_api eval BankingApi.Release.migrate

#start application
bin/banking_api start
