 #!/bin/sh
appdir=$(mktemp -d /tmp/app.XXXXXX)
cp $(dirname $0)/* $appdir/
pushd $appdir > /dev/null
npm install
if [ $? -ne 0 ]
then
    echo "FAILD TO BUILD THE CONFIG SCRIPT"
    exit 1
fi

kubectl port-forward $(kubectl get pod | grep keycloak | cut -d ' ' -f 1) 8080:8080 &
PID=$!

sleep 3

npm start
if [ $? -ne 0 ]
then
    echo "FAILD TO RUN THE CONFIG SCRIPT"
    exit 2
fi

kill $PID
popd > /dev/null