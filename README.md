# Deploying Flexcube in OCI OKE with ORACLE VISUAL BUILDER STUDIO

Observations:

* Layers for Containerization
   * Fusion
   * Flexcube
   * WebLogic Configuration
   * Database Configuration
   * Flexcube Servers

### For manual deployment (Simple way)

    If you already have a Pod/Deployment:

    kubectl delete deployment integrated144-deployment
   
    ------
  
    Or if you want to create a new Deployment:
 
    kubectl apply -f integrated144.yaml
    
    kubectl exec $(kubectl get pod -l app=integrated144 -o jsonpath="{.items[0].metadata.name}") -- /bin/bash -c "wget https://objectstorage.us-ashburn-1.oraclecloud.com/p/0YTvKvrmiae_ZUoq4ft48Wt3eQfZRCYlrIgjrzADHdJfkkyfkr_4lA4PNF8MrOCj/n/id3kyspkytmr/b/bucket_banco_conceito/o/initializeConfig.sh"
    
    kubectl exec $(kubectl get pod -l app=integrated144 -o jsonpath="{.items[0].metadata.name}") -- /bin/bash -c "sh initializeConfig.sh jdbc:oracle:thin:@132.145.191.118:1521/DB0401_iad15g.subnet04010815.vcn04010815.oraclevcn.com {AES256}7kfaltdnEBjKNqdHFhUn7o10DRIU0IcLOynq1ee8Ib8="


### Building Flexcube Docker Image


    sudo docker run --name integrated144 -h "fcubs.oracle.com" -p 7001-7020:7001-7020 -it "iad.ocir.io/id3kyspkytmr/oraclefmw-infra_with_patch:12.2.1.4.0" /bin/bash

### Merge Fusion Docker Image with Flexcube

    flexcube.sh
    
    su - gsh
    wget https://objectstorage.us-ashburn-1.oraclecloud.com/p/Y86rX7N3n5m39BuMsxkRY-uP5O1ha2ZVEOv-oazTmA6MDf0XNtki8gGymsvYvPEf/n/id3kyspkytmr/b/bucket_banco_conceito/o/kernel144_11Mar21.zip
    unzip kernel144_11Mar21.zip
    mv scratch/gsh/kernel144/ /scratch/gsh
    cd /scratch/gsh/kernel144/user_projects/domains/integrated/bin

Then execute:


    sudo docker cp flexcube.sh integrated144:/

    sudo docker start integrated144

    sudo docker exec integrated144 /bin/bash -c "sh /flexcube.sh"

Test if docker image is OK:

    sudo docker exec integrated144 /bin/bash -c "sh /scratch/gsh/kernel144/user_projects/domains/integrated/bin/startNodeManager.sh &"

    sudo docker exec integrated144 /bin/bash -c "sh /scratch/gsh/kernel144/user_projects/domains/integrated/bin/startWebLogic.sh &"
    
And for push the docker image to OCIR:

    sudo docker stop integrated144

    sudo docker commit integrated144 flexcube/integrated144:v1
    sudo docker tag flexcube/integrated144:v1 iad.ocir.io/id3kyspkytmr/flexcube/integrated144:v1
    sudo docker push iad.ocir.io/id3kyspkytmr/flexcube/integrated144:v1

The Flexcube team needs to build the image with:

    Fusion Middleware
    Flexcube (/scratch/gsh/...)

### Automating the deployment for OKE

#### Change Database Password to AES format with weblogic.security.Encrypt

    cd /scratch/gsh/oracle/wlserver/server/bin
    .  ./setWLSEnv.sh
    java -Dweblogic.RootDirectory=/scratch/gsh/kernel144/user_projects/domains/integrated  weblogic.security.Encrypt INt#grat#d144

#### Environment Variables

    $JDBCPassword: {AES256}7kfaltdnEBjKNqdHFhUn7o10DRIU0IcLOynq1ee8Ib8=     (In AES format*)
    $JDBCString: jdbc:oracle:thin:@132.145.191.118:1521/DB0401_iad15g.subnet04010815.vcn04010815.oraclevcn.com

#
    OCI CLI Install
    Unix Shell


    #  Prepare for kubectl from OCI CLI
    mkdir -p $HOME/.kube
    oci ce cluster create-kubeconfig --cluster-id ocid1.cluster.oc1.iad.aaaaaaaaae3tmyldgbtgmyjrmyzdeytbhazdmmbrgfstmntdgc2wmzrxgbrt --file $HOME/.kube/config --region us-ashburn-1 --token-version 2.0.0
    export KUBECONFIG=$HOME/.kube/config
    # Deploy integrated144
    kubectl config view
    kubectl get nodes
    kubectl replace -f integrated144.yaml --force
    kubectl rollout status deployment integrated144-deployment
    # Set Variables
    export JDBCString=$JDBCString
    export JDBCPassword=$JDBCPassword
    # Install tar
    kubectl exec $(kubectl get pod -l app=integrated144 -o jsonpath="{.items[0].metadata.name}") -- /bin/bash -c "yum install tar -y"
    # Copy files to automation
    touch domainsDetails.properties
    echo "ds.jdbc.new.1=$JDBCString" > domainsDetails.properties
    echo "ds.password.new.1=$JDBCPassword" >> domainsDetails.properties
    kubectl cp domainsDetails.properties $(kubectl get pod -l app=integrated144 -o jsonpath="{.items[0].metadata.name}"):/
    kubectl cp ChangeJDBC.py $(kubectl get pod -l app=integrated144 -o jsonpath="{.items[0].metadata.name}"):/
    kubectl cp ChangeJDBC.sh $(kubectl get pod -l app=integrated144 -o jsonpath="{.items[0].metadata.name}"):/
    kubectl cp ExecuteWebLogic.sh $(kubectl get pod -l app=integrated144 -o jsonpath="{.items[0].metadata.name}"):/
    kubectl cp StartApps.py $(kubectl get pod -l app=integrated144 -o jsonpath="{.items[0].metadata.name}"):/
    kubectl cp StartApps.sh $(kubectl get pod -l app=integrated144 -o jsonpath="{.items[0].metadata.name}"):/
    kubectl cp ShutdownAdminServer.sh $(kubectl get pod -l app=integrated144 -o jsonpath="{.items[0].metadata.name}"):/
    kubectl cp ShutdownAdminServer.py $(kubectl get pod -l app=integrated144 -o jsonpath="{.items[0].metadata.name}"):/
    kubectl cp ExecuteWebLogicOnly.sh $(kubectl get pod -l app=integrated144 -o jsonpath="{.items[0].metadata.name}"):/
    kubectl cp JDBCReplace.sh $(kubectl get pod -l app=integrated144 -o jsonpath="{.items[0].metadata.name}"):/
    kubectl cp JDBCList $(kubectl get pod -l app=integrated144 -o jsonpath="{.items[0].metadata.name}"):/
    kubectl cp RestartFlexcube.sh $(kubectl get pod -l app=integrated144 -o jsonpath="{.items[0].metadata.name}"):/
    # Change JDBC configuration
    kubectl exec $(kubectl get pod -l app=integrated144 -o jsonpath="{.items[0].metadata.name}") -- /bin/bash -c "sh /JDBCReplace.sh /JDBCList $JDBCString $JDBCPassword"
    # Run Weblogic
    kubectl exec $(kubectl get pod -l app=integrated144 -o jsonpath="{.items[0].metadata.name}") -- /bin/bash -c "sh /ExecuteWebLogic.sh"
    sleep 180
    # Start Apps
    kubectl exec $(kubectl get pod -l app=integrated144 -o jsonpath="{.items[0].metadata.name}") -- /bin/bash -c "sh /StartApps.sh"
    kubectl get pods

# 

    YAML (~/Dropbox/Oracle/MyWork/DevOps/flexcube/integrated144.yaml)

    apiVersion: apps/v1
    kind: Deployment
    metadata:
      name: integrated144-deployment
    spec:
      replicas: 1
      selector:
        matchLabels:
          app: integrated144
      template:
    metadata:
          labels:
            app: integrated144
        spec:
          containers:
          - name: integrated144
            image: iad.ocir.io/id3kyspkytmr/flexcube/integrated144:v1
            command: [ "/bin/bash", "-c", "--" ]
            args: [ "while true; do sleep 30; done;" ]
            ports:
            - name: port7001
              containerPort: 7001
            - name: port7004
              containerPort: 7004
          imagePullSecrets:
          - name: ocirsecret
    ---
    apiVersion: v1
    kind: Service
    metadata:
      name: integrated144-service
      labels:
        app: integrated144
    spec:
      selector:
        app: integrated144
      ports:
        - port: 7004
          targetPort: 7004
      type: LoadBalancer
    ---
    apiVersion: v1
    kind: Service
    metadata:
      name: integrated144-service-weblogic
      labels:
        app: integrated144
    spec:
      selector:
        app: integrated144
      ports:
        - port: 7001
          targetPort: 7001
      type: LoadBalancer
    ---
    apiVersion: v1
    kind: Service
    metadata:
      name: integrated144-webservices
      labels:
        app: integrated144
    spec:
      selector:
        app: integrated144
      ports:
        - port: 7005
          targetPort: 7005
      type: LoadBalancer

### Manual Controls

If you want to start or stop WebLogic, you can execute these commands.

#### Execute WebLogic

    kubectl exec $(kubectl get pod -l app=integrated144 -o jsonpath="{.items[0].metadata.name}") -- /bin/bash -c "sh /scratch/gsh/kernel144/user_projects/domains/integrated/bin/startNodeManager.sh &"

    kubectl exec $(kubectl get pod -l app=integrated144 -o jsonpath="{.items[0].metadata.name}") -- /bin/bash -c "sh /scratch/gsh/kernel144/user_projects/domains/integrated/bin/startWebLogic.sh &"

#### Stop WebLogic

    kubectl exec $(kubectl get pod -l app=integrated144 -o jsonpath="{.items[0].metadata.name}") -- /bin/bash -c "sh /scratch/gsh/kernel144/user_projects/domains/integrated/bin/stopNodeManager.sh &"

    kubectl exec $(kubectl get pod -l app=integrated144 -o jsonpath="{.items[0].metadata.name}") -- /bin/bash -c "sh /scratch/gsh/kernel144/user_projects/domains/integrated/bin/stopWebLogic.sh &"

#### Changing Database Passwords in JDBC Configuration

    domainsDetails.properties

    ds.jdbc.new.1=jdbc:oracle:thin:@132.145.191.118:1521/DB0401_iad15g.subnet04010815.vcn04010815.oraclevcn.com
    ds.password.new.1={AES256}7kfaltdnEBjKNqdHFhUn7o10DRIU0IcLOynq1ee8Ib8=

#

    ChangeJDBC.py

    from java.io import FileInputStream

    propInputStream = FileInputStream("/domainsDetails.properties")
    configProps = Properties()
    configProps.load(propInputStream)
    
    for i in 1,1:
        newJDBCString = configProps.get("ds.jdbc.new."+ str(i))
        newDSPassword = configProps.get("ds.password.new."+ str(i))
        i = i + 1
    
        print("*** Trying to Connect.... *****")
        connect('weblogic','weblogic123','t3://localhost:7001')
        print("*** Connected *****")
        cd('/Servers/AdminServer')
        edit()
        startEdit()
        cd('JDBCSystemResources')
        pwd()
        ls()
        allDS=cmo.getJDBCSystemResources()
        for tmpDS in allDS:
                   dsName=tmpDS.getName();
                   print 'DataSource Name: ', dsName
                   print ' '
                   print ' '
                   print 'Changing Password & URL for DataSource ', dsName
                   cd('/JDBCSystemResources/'+dsName+'/JDBCResource/'+dsName+'/JDBCDriverParams/'+dsName)
                   print('/JDBCSystemResources/'+dsName+'/JDBCResource/'+dsName+'/JDBCDriverParams/'+dsName)
                   set('PasswordEncrypted', newDSPassword)
                   cd('/JDBCSystemResources/'+dsName+'/JDBCResource/'+dsName+'/JDBCDriverParams/'+dsName)
                   set('Url',newJDBCString)
                   print("*** CONGRATES !!! Username & Password has been Changed for DataSource: ", dsName)
                   print ('')
                   print ('')

    save()
    activate()

#

    ChangeJDBC.sh

    cd /scratch/gsh/oracle/wlserver/server/bin
    .  ./setWLSEnv.sh
    java weblogic.WLST /ChangeJDBC.py

#

#### Starting NodeManager and WebLogic

    ExecuteWebLogic.sh

    cd /
    su - gsh
    cd /scratch/gsh/kernel144/user_projects/domains/integrated/bin
    sh /scratch/gsh/kernel144/user_projects/domains/integrated/bin/startNodeManager.sh &
    sh /scratch/gsh/kernel144/user_projects/domains/integrated/bin/startWebLogic.sh &

#

    StartApps.py

    from java.io import FileInputStream
    
    print("*** Trying to Connect.... *****")
    connect('weblogic','weblogic123','t3://localhost:7001')
    print("*** Connected *****")
    
    start('gateway_server')
    start('rest_server')
    start('integrated_server')
    
    disconnect()
    exit()

#

    StartApps.sh

    cd /scratch/gsh/oracle/wlserver/server/bin
    .  ./setWLSEnv.sh
    java weblogic.WLST /StartApps.py
    
#

    RestartFlexcube.sh

    cd /
    sh ExecuteWebLogic.sh
    sleep 180
    cd /
    sh StartApps.sh

#

    JDBCReplace.sh

    #!/bin/bash
    su - gsh
    filename=$1
    while read line; do
    # reading each line
    echo $line
    sed -i 's/<url>jdbc:oracle:thin:@whf00fxh.in.oracle.com:1521\/prodpdb<\/url>/<url>$JDBCString<\/url>/' /scratch/gsh/kernel144/user_projects/domains/integrated/config/jdbc/$line
    sed -i 's/<password-encrypted><\/password-encrypted>/<password-encrypted>$JDBCPassword<\/password-encrypted>/' /scratch/gsh/kernel144/user_projects/domains/integrated/config/jdbc/$line
    done < $filename

#

    JDBCList

    FLEXTEST2eMDB-9656-jdbc.xml
    jdbc2ffcelcmDS-6351-jdbc.xml
    jdbc2ffcjdevDSBranch-1885-jdbc.xml
    jdbc2ffcjdevDS_EL-0091-jdbc.xml
    jdbc2ffcjpmDS_GTXN-9747-jdbc.xml
    FLEXTEST2eWORLD-1247-jdbc.xml
    jdbc2ffcjDevXADS-7492-jdbc.xml
    jdbc2ffcjdevDSSMS-8814-jdbc.xml
    jdbc2ffcjdevDS_GTXN-7273-jdbc.xml
    jdbc2ffcjsmsDS-7727-jdbc.xml
    jdbc2fINT144_integrated144-0549-jdbc.xml
    jdbc2ffcjSchedulerDS-6833-jdbc.xml
    jdbc2ffcjdevDSSMS_XA-5306-jdbc.xml
    jdbc2ffcjdevDS_XA-0669-jdbc.xml
    jdbc2fODT14_4-1795-jdbc.xml
    jdbc2ffcjdevDS-9467-jdbc.xml
    jdbc2ffcjdevDS_ASYNC-6792-jdbc.xml
    jdbc2ffcjpmDS-1925-jdbc.xml


