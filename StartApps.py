from java.io import FileInputStream

print("*** Trying to Connect.... *****")
connect('weblogic','weblogic123','t3://localhost:7001')
print("*** Connected *****")

start('gateway_server')
start('rest_server')
start('integrated_server')

disconnect()
exit()

