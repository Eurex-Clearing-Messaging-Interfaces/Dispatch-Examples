#!/usr/bin/env bats

FIXML_IMAGE="ecmi/fixml"
FIXML_VERSION="sim"
DISPATCH_IMAGE="scholzj/qpid-dispatch"
DISPATCH_VERSION="0.6.0-rc1"

#setup() {
#    export QPID_SSL_CERT_DB=sql:./tests/
#    export QPID_SSL_CERT_PASSWORD_FILE=./tests/pwdfile
#    export QPID_SSL_CERT_NAME=ABCFR_ABCFRALMMACC1
#}

teardown() {
    sudo docker stop $contFixml
    sudo docker rm $contFixml
    sudo docker stop $contDisp
    sudo docker rm $contDisp
}

tcpPortFixml() {
    sudo docker port $contFixml 5672 | cut -f 2 -d ":"
}

sslPortFixml() {
    sudo docker port $contFixml 5671 | cut -f 2 -d ":"
}

tcpPortDisp() {
    sudo docker port $contDisp 5672 | cut -f 2 -d ":"
}

@test "Test TradeConfirmation broadcasts on ABCFR->user1 using link routing" {
    contFixml=$(sudo docker run -P --name fixml -d $FIXML_IMAGE:$FIXML_VERSION)
    tcpFixml=$(tcpPortFixml)

    contDisp=$(sudo docker run -P -v $(pwd)/:/var/lib/qpid-dispatch/:z --link fixml:fixml1 --link fixml:fixml2 -d $DISPATCH_IMAGE:$DISPATCH_VERSION --config /var/lib/qpid-dispatch/qdrouterd-link-routing.conf)
    tcpDisp=$(tcpPortDisp)

    sleep 5 # give the image time to start

    run qpid-send -b admin/admin@ecag-fixml-dev1:$tcpFixml -a "broadcast/broadcast.ABCFR.TradeConfirmation; { node: { type: topic}, assert: never, create: never }" -m 1 --durable yes --content-size 1024
    echo $output
    [ "$status" -eq "0" ]

    run qpid-receive -b ecag-fixml-dev1:$tcpDisp --connection-options "{ protocol: amqp1.0, sasl_mechanism: PLAIN, username: user1@QPID, password: 123456 }" -a "broadcast.ABCFR_ABCFRALMMACC1.TradeConfirmation; { node: { type: queue}, assert: never, create: never }" -m 1 --timeout 5 --report-total --report-header no --print-content no
    echo $output
    [ "$status" -eq "0" ]
    [ "${lines[0]}" != "0" ]
}
