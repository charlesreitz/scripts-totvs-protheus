#!/bin/bash
service totvsdbaccess start
service ctreeserver start
sleep 5
service totvsprotheus00 start
#service totvsprotheusweb start
service totvsprotheusatu start
