#!/usr/bin/env bats

FIXML_IMAGE="ecmi/fixml"
FIXML_VERSION="sim"
DISPATCH_IMAGE="scholzj/qpid-dispatch"
DISPATCH_VERSION="0.8.0-rc2"

teardown() {
    sudo docker stop $contFixml
    sudo docker stop $contDisp
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

#########
#########
#
# Link routing
#
#########
#########

@test "Test TradeConfirmation broadcasts on ABCFR->user1 using link routing" {
    contFixml=$(sudo docker run -P -d $FIXML_IMAGE:$FIXML_VERSION)
    tcpFixml=$(tcpPortFixml)

    contDisp=$(sudo docker run -P -v $(pwd)/:/var/lib/qpid-dispatch/:z --link ${contFixml}:ecag-fixml-dev1 -d $DISPATCH_IMAGE:$DISPATCH_VERSION  /usr/sbin/qdrouterd --config /var/lib/qpid-dispatch/qdrouterd-link-routing.conf)
    tcpDisp=$(tcpPortDisp)

    sleep 5 # give the image time to start

    run qpid-send -b admin/admin@localhost:$tcpFixml -a "broadcast/broadcast.ABCFR.TradeConfirmation; { node: { type: topic}, assert: never, create: never }" -m 1 --durable yes --content-size 1024
    echo $output
    [ "$status" -eq "0" ]

    sleep 5 # some time to send the messag

    run qpid-receive -b localhost:$tcpDisp --connection-options "{ protocol: amqp1.0, sasl_mechanism: PLAIN, username: user1@QPID, password: 123456 }" -a "broadcast.ABCFR_ABCFRALMMACC1.TradeConfirmation; { node: { type: queue}, assert: never, create: never }" -m 1 --timeout 5 --report-total --report-header no --print-content no
    echo $output
    [ "$status" -eq "0" ]
    [ "${lines[0]}" != "0" ]
}

@test "Test TradeConfirmation broadcasts on DEFFR->user2 using link routing" {
    contFixml=$(sudo docker run -P -d $FIXML_IMAGE:$FIXML_VERSION)
    tcpFixml=$(tcpPortFixml)

    contDisp=$(sudo docker run -P -v $(pwd)/:/var/lib/qpid-dispatch/:z --link ${contFixml}:ecag-fixml-dev1 -d $DISPATCH_IMAGE:$DISPATCH_VERSION  /usr/sbin/qdrouterd --config /var/lib/qpid-dispatch/qdrouterd-link-routing.conf)
    tcpDisp=$(tcpPortDisp)

    sleep 5 # give the image time to start

    run qpid-send -b admin/admin@localhost:$tcpFixml -a "broadcast/broadcast.DEFFR.TradeConfirmation; { node: { type: topic}, assert: never, create: never }" -m 1 --durable yes --content-size 1024
    echo $output
    [ "$status" -eq "0" ]

    sleep 5 # some time to send the message

    run qpid-receive -b localhost:$tcpDisp --connection-options "{ protocol: amqp1.0, sasl_mechanism: PLAIN, username: user2@QPID, password: 123456 }" -a "broadcast.DEFFR_DEFFRALMMACC1.TradeConfirmation; { node: { type: queue}, assert: never, create: never }" -m 1 --timeout 5 --report-total --report-header no --print-content no
    echo $output
    [ "$status" -eq "0" ]
    [ "${lines[0]}" != "0" ]
}

@test "Test request ABCFR->user1 using link routing" {
    contFixml=$(sudo docker run -P -d $FIXML_IMAGE:$FIXML_VERSION)
    tcpFixml=$(tcpPortFixml)

    contDisp=$(sudo docker run -P -v $(pwd)/:/var/lib/qpid-dispatch/:z --link ${contFixml}:ecag-fixml-dev1 -d $DISPATCH_IMAGE:$DISPATCH_VERSION  /usr/sbin/qdrouterd --config /var/lib/qpid-dispatch/qdrouterd-link-routing.conf)
    tcpDisp=$(tcpPortDisp)

    sleep 5 # give the image time to start

    run qpid-send -b localhost:$tcpDisp --connection-options "{ protocol: amqp1.0, sasl_mechanism: PLAIN, username: user1@QPID, password: 123456 }" -a "request.ABCFR_ABCFRALMMACC1; { node: { type: topic}, assert: never, create: never }" -m 1 --durable yes --content-size 1024
    [ "$status" -eq "0" ]

    sleep 5 # some time to send the messag

    run qpid-receive -b admin/admin@localhost:$tcpFixml --connection-options "{ protocol: amqp0-10, sasl_mechanism: PLAIN }" -a "request_be.ABCFR_ABCFRALMMACC1; { node: { type: queue}, assert: never, create: never }" -m 1 --timeout 5 --report-total --report-header no --print-content no
    echo $output
    [ "$status" -eq "0" ]
    [ "${lines[0]}" != "0" ]
}

@test "Test response on ABCFR->user1 using link routing" {
    contFixml=$(sudo docker run -P -d $FIXML_IMAGE:$FIXML_VERSION)
    tcpFixml=$(tcpPortFixml)

    contDisp=$(sudo docker run -P -v $(pwd)/:/var/lib/qpid-dispatch/:z --link ${contFixml}:ecag-fixml-dev1 -d $DISPATCH_IMAGE:$DISPATCH_VERSION  /usr/sbin/qdrouterd --config /var/lib/qpid-dispatch/qdrouterd-link-routing.conf)
    tcpDisp=$(tcpPortDisp)

    sleep 5 # give the image time to start

    run qpid-send -b admin/admin@localhost:$tcpFixml -a "response/response.ABCFR_ABCFRALMMACC1; { node: { type: topic}, assert: never, create: never }" -m 1 --durable yes --content-size 1024
    echo $output
    [ "$status" -eq "0" ]

    sleep 5 # some time to send the messag

    run qpid-receive -b localhost:$tcpDisp --connection-options "{ protocol: amqp1.0, sasl_mechanism: PLAIN, username: user1@QPID, password: 123456 }" -a "response.ABCFR_ABCFRALMMACC1; { node: { type: queue}, assert: never, create: never }" -m 1 --timeout 5 --report-total --report-header no --print-content no
    echo $output
    [ "$status" -eq "0" ]
    [ "${lines[0]}" != "0" ]
}

@test "Test request ABCFR->user2 using link routing - should be forbidden by policy" {
    contFixml=$(sudo docker run -P -d $FIXML_IMAGE:$FIXML_VERSION)
    tcpFixml=$(tcpPortFixml)

    contDisp=$(sudo docker run -P -v $(pwd)/:/var/lib/qpid-dispatch/:z --link ${contFixml}:ecag-fixml-dev1 -d $DISPATCH_IMAGE:$DISPATCH_VERSION  /usr/sbin/qdrouterd --config /var/lib/qpid-dispatch/qdrouterd-link-routing.conf)
    tcpDisp=$(tcpPortDisp)

    sleep 5 # give the image time to start

    run qpid-send -b localhost:$tcpDisp --connection-options "{ protocol: amqp1.0, sasl_mechanism: PLAIN, username: user2@QPID, password: 123456 }" -a "request.ABCFR_ABCFRALMMACC1; { node: { type: topic}, assert: never, create: never }" -m 1 --durable yes --content-size 1024
    [ "$status" -ne "0" ]
}

@test "Test response on ABCFR->user2 using link routing - should be forbidden by policy" {
    contFixml=$(sudo docker run -P -d $FIXML_IMAGE:$FIXML_VERSION)
    tcpFixml=$(tcpPortFixml)

    contDisp=$(sudo docker run -P -v $(pwd)/:/var/lib/qpid-dispatch/:z --link ${contFixml}:ecag-fixml-dev1 -d $DISPATCH_IMAGE:$DISPATCH_VERSION  /usr/sbin/qdrouterd --config /var/lib/qpid-dispatch/qdrouterd-link-routing.conf)
    tcpDisp=$(tcpPortDisp)

    sleep 5 # give the image time to start

    run qpid-receive -b localhost:$tcpDisp --connection-options "{ protocol: amqp1.0, sasl_mechanism: PLAIN, username: user2@QPID, password: 123456 }" -a "response.ABCFR_ABCFRALMMACC1; { node: { type: queue}, assert: never, create: never }" -m 1 --timeout 5 --report-total --report-header no --print-content no
    echo $output
    [ "$status" -ne "0" ]
}

##########
##########
#
# Message routing
#
##########
##########

@test "Test TradeConfirmation broadcasts on ABCFR->user1 using message routing" {
    contFixml=$(sudo docker run -P -d $FIXML_IMAGE:$FIXML_VERSION)
    tcpFixml=$(tcpPortFixml)

    contDisp=$(sudo docker run -P -v $(pwd)/:/var/lib/qpid-dispatch/:z --link ${contFixml}:ecag-fixml-dev1 -d $DISPATCH_IMAGE:$DISPATCH_VERSION  /usr/sbin/qdrouterd --config /var/lib/qpid-dispatch/qdrouterd-message-routing.conf)
    tcpDisp=$(tcpPortDisp)

    sleep 5 # give the image time to start

    run qpid-send -b admin/admin@localhost:$tcpFixml -a "broadcast/broadcast.ABCFR.TradeConfirmation; { node: { type: topic}, assert: never, create: never }" -m 1 --durable yes --content-size 1024
    echo $output
    [ "$status" -eq "0" ]

    sleep 5 # some time to send the messag

    run qpid-receive -b localhost:$tcpDisp --connection-options "{ protocol: amqp1.0, sasl_mechanism: PLAIN, username: user1@QPID, password: 123456 }" -a "broadcast.ABCFR_ABCFRALMMACC1.TradeConfirmation; { node: { type: queue}, assert: never, create: never }" -m 1 --timeout 5 --report-total --report-header no --print-content no
    echo $output
    [ "$status" -eq "0" ]
    [ "${lines[0]}" != "0" ]
}

@test "Test TradeConfirmation broadcasts on DEFFR->user2 using message routing" {
    contFixml=$(sudo docker run -P -d $FIXML_IMAGE:$FIXML_VERSION)
    tcpFixml=$(tcpPortFixml)

    contDisp=$(sudo docker run -P -v $(pwd)/:/var/lib/qpid-dispatch/:z --link ${contFixml}:ecag-fixml-dev1 -d $DISPATCH_IMAGE:$DISPATCH_VERSION  /usr/sbin/qdrouterd --config /var/lib/qpid-dispatch/qdrouterd-message-routing.conf)
    tcpDisp=$(tcpPortDisp)

    sleep 5 # give the image time to start

    run qpid-send -b admin/admin@localhost:$tcpFixml -a "broadcast/broadcast.DEFFR.TradeConfirmation; { node: { type: topic}, assert: never, create: never }" -m 1 --durable yes --content-size 1024
    echo $output
    [ "$status" -eq "0" ]

    sleep 5 # some time to send the messag

    run qpid-receive -b localhost:$tcpDisp --connection-options "{ protocol: amqp1.0, sasl_mechanism: PLAIN, username: user2@QPID, password: 123456 }" -a "broadcast.DEFFR_DEFFRALMMACC1.TradeConfirmation; { node: { type: queue}, assert: never, create: never }" -m 1 --timeout 5 --report-total --report-header no --print-content no
    echo $output
    [ "$status" -eq "0" ]
    [ "${lines[0]}" != "0" ]
}

@test "Test request ABCFR->user1 using message routing" {
    contFixml=$(sudo docker run -P -d $FIXML_IMAGE:$FIXML_VERSION)
    tcpFixml=$(tcpPortFixml)

    contDisp=$(sudo docker run -P -v $(pwd)/:/var/lib/qpid-dispatch/:z --link ${contFixml}:ecag-fixml-dev1 -d $DISPATCH_IMAGE:$DISPATCH_VERSION  /usr/sbin/qdrouterd --config /var/lib/qpid-dispatch/qdrouterd-message-routing.conf)
    tcpDisp=$(tcpPortDisp)

    sleep 5 # give the image time to start

    run qpid-send -b localhost:$tcpDisp --connection-options "{ protocol: amqp1.0, sasl_mechanism: PLAIN, username: user1@QPID, password: 123456 }" -a "request.ABCFR_ABCFRALMMACC1; { node: { type: topic}, assert: never, create: never }" -m 1 --durable yes --content-size 1024
    [ "$status" -eq "0" ]

    sleep 5 # some time to send the messag

    run qpid-receive -b admin/admin@localhost:$tcpFixml --connection-options "{ protocol: amqp0-10, sasl_mechanism: PLAIN }" -a "request_be.ABCFR_ABCFRALMMACC1; { node: { type: queue}, assert: never, create: never }" -m 1 --timeout 5 --report-total --report-header no --print-content no
    echo $output
    [ "$status" -eq "0" ]
    [ "${lines[0]}" != "0" ]
}

@test "Test response on ABCFR->user1 using message routing" {
    contFixml=$(sudo docker run -P -d $FIXML_IMAGE:$FIXML_VERSION)
    tcpFixml=$(tcpPortFixml)

    contDisp=$(sudo docker run -P -v $(pwd)/:/var/lib/qpid-dispatch/:z --link ${contFixml}:ecag-fixml-dev1 -d $DISPATCH_IMAGE:$DISPATCH_VERSION  /usr/sbin/qdrouterd --config /var/lib/qpid-dispatch/qdrouterd-message-routing.conf)
    tcpDisp=$(tcpPortDisp)

    sleep 5 # give the image time to start

    run qpid-send -b admin/admin@localhost:$tcpFixml -a "response/response.ABCFR_ABCFRALMMACC1; { node: { type: topic}, assert: never, create: never }" -m 1 --durable yes --content-size 1024
    echo $output
    [ "$status" -eq "0" ]

    sleep 5 # some time to send the messag

    run qpid-receive -b localhost:$tcpDisp --connection-options "{ protocol: amqp1.0, sasl_mechanism: PLAIN, username: user1@QPID, password: 123456 }" -a "response.ABCFR_ABCFRALMMACC1; { node: { type: queue}, assert: never, create: never }" -m 1 --timeout 5 --report-total --report-header no --print-content no
    echo $output
    [ "$status" -eq "0" ]
    [ "${lines[0]}" != "0" ]
}

@test "Test request ABCFR->user2 using message routing - should be forbidden by policy" {
    contFixml=$(sudo docker run -P -d $FIXML_IMAGE:$FIXML_VERSION)
    tcpFixml=$(tcpPortFixml)

    contDisp=$(sudo docker run -P -v $(pwd)/:/var/lib/qpid-dispatch/:z --link ${contFixml}:ecag-fixml-dev1 -d $DISPATCH_IMAGE:$DISPATCH_VERSION  /usr/sbin/qdrouterd --config /var/lib/qpid-dispatch/qdrouterd-message-routing.conf)
    tcpDisp=$(tcpPortDisp)

    sleep 5 # give the image time to start

    run qpid-send -b localhost:$tcpDisp --connection-options "{ protocol: amqp1.0, sasl_mechanism: PLAIN, username: user2@QPID, password: 123456 }" -a "request.ABCFR_ABCFRALMMACC1; { node: { type: topic}, assert: never, create: never }" -m 1 --durable yes --content-size 1024
    [ "$status" -ne "0" ]
}

@test "Test response on ABCFR->user2 using message routing - should be forbidden by policy" {
    contFixml=$(sudo docker run -P -d $FIXML_IMAGE:$FIXML_VERSION)
    tcpFixml=$(tcpPortFixml)

    contDisp=$(sudo docker run -P -v $(pwd)/:/var/lib/qpid-dispatch/:z --link ${contFixml}:ecag-fixml-dev1 -d $DISPATCH_IMAGE:$DISPATCH_VERSION  /usr/sbin/qdrouterd --config /var/lib/qpid-dispatch/qdrouterd-message-routing.conf)
    tcpDisp=$(tcpPortDisp)

    sleep 5 # give the image time to start

    run qpid-receive -b localhost:$tcpDisp --connection-options "{ protocol: amqp1.0, sasl_mechanism: PLAIN, username: user2@QPID, password: 123456 }" -a "response.ABCFR_ABCFRALMMACC1; { node: { type: queue}, assert: never, create: never }" -m 1 --timeout 5 --report-total --report-header no --print-content no
    echo $output
    [ "$status" -ne "0" ]
}
