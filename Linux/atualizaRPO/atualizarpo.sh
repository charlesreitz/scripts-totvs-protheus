#!/bin/bash
#################################
# Empresa: Totvs S.A            #
# Autor..: Sergio Barkemeyer    #
# Criacao: 19/02/2010           #
# Modific: 01/04/2010           #
# Favor nao apagar os creditos  #
#################################

# INICIO
#------------------------------------------------
# definicao de constantes
  totvsdir="/totvs12/microsiga/protheus/bin"
  inifile="/totvs12/microsiga/protheus/bin/inifile"
  pastaapo="/totvs12/microsiga/protheus/apo"
  rpo="tttp120.rpo"
  prefixnovo=$(date +%Y%m%d)
  seqnovo=1
#------------------------------------------------

  clear
  echo -e ""
  echo -e "Rotina de Atualizacao de Repositorio "
  echo -e "-------------------------------------"
  echo -e ""
  echo -e "(Para abortar o processo, tecle Ctrl+C)"
  echo -e ""

  if  [ $# -gt 0 ];
  then
       opcao=$1
  else
       echo -e "Informe a opcao desejada:"
       echo -e "   1 => Atualiza RPOs do ambiente protheus"
       echo -e ""
       echo -e "Opcao: "

       read opcao
       echo ""
  fi


  case $opcao in
       1)
         ini=$totvsdir/appserver00/appserver.ini
         ambiente="protheus"
         pastaapo=$pastaapo
         # Pasta de onde o RPO atualizado sera copiado
         pastaatu='/totvs12/microsiga/protheus/apo/atu'

         # Lista de servidores a serem atualizados
         #aServers=( local 192.168.2.214 )
         aServers=( local )

         # Lista das pastas dos servers a serem atualizados
         aDirServers=( appserver00 appserverweb )

         # Lista das ambientes dos servers a serem atualizados
         #aAmbientes=( environment administ )
         aAmbientes=( protheus )
         ;;
       *)
         echo "Opcao invalida!"
         exit -1
         ;;
  esac

  pastaatu_aux=`$inifile $ini $ambiente SourcePath`
  echo -e "------------------------------------------------------"
  echo -e "Pasta atual.............: $pastaatu_aux"
  echo -e "------------------------------------------------------"
  echo -e ""


  # verifica espaco em disco disponivel
  for sServer in ${aServers[*]}; do
          echo -e ""
          echo -e "Verificando espaco em disco disponivel......"
          if [ $sServer == 'local' ];
          then
                #pctusado=`df -lh | grep / |  awk '{ print $4}' | grep %`
                pctusado=`df -lh | grep rhel\-root  |  awk '{ print $5}' | grep %`
          else
                pctusado=`ssh $sServer df -lh | grep / |  awk '{ print $4}' | grep %`
          fi
          valor=${pctusado//%/}
          if [ $valor -gt 80 ];
          then
              echo -e "Espaco em disco disponivel no servidor $sServer esta abaixo de 15% (usado: $pctusado)"
              echo -e "Deseja continuar com a atualizacao? [s ou n]:"
              read opcaoatu
              if   [ $opcaoatu = S -o $opcaoatu = s ];
              then if [ $valor -gt 90 ];
                   then
                       echo -e "Espaco em disco insuficiente para fazer novas atualizacoes."
                       echo -e "\n\n>>>>>>>>>>>> Processo cancelado. <<<<<<<<<<<<<<<\n\n"
                       exit -1
                   fi
              else
                   exit
              fi
          fi
  done

  cd $pastaapo
  pastanova=$prefixnovo"_"$seqnovo

  while true
  do
    if [ -d $pastanova ];
    then seqnovo=$((seqnovo + 1))
         pastanova=$prefixnovo"_"$seqnovo
    else mkdir $pastanova
         echo -e "------------------------------------------------------"
         echo -e "Pasta nova .............: $pastaapo/$pastanova"
         echo -e "------------------------------------------------------"
         break
    fi
  done

  for sServer in ${aServers[*]}; do
         if [ $sServer == 'local' ];
         then
                echo -e "Copiando RPO para nova pasta. AGUARDE..."
                cp -p $pastaatu/$rpo $pastaapo/$pastanova/.

                # altera appserver.ini de Todos AppServer no servidor local
                echo -e "Atualizando appserver.ini de TODOS Appservers. Aguarde..."
                # Atualizar pastas no servidor local
                for sDir in ${aDirServers[*]}; do
                        for sEnv in ${aAmbientes[*]}; do
                                $inifile $totvsdir/$sDir/appserver.ini $sEnv SourcePath $pastaapo/$pastanova
                        done
                done
         else
                #-------------------------------------------------
                # copia rpo para outra maquina
                echo -e "Copiando RPO para maquina $sServer. AGUARDE..."
                scp -rp $pastaapo/$pastanova $sServer:$pastaapo

                # Altera o appserver.ini nas outras maquinas
                echo -e "Atualizando appserver.ini de TODOS Appservers em $sServer. Aguarde..."
                # Atualizar pastas dos servers remotos
                for sDir in ${aDirServers[*]}; do
                        for sEnv in ${aAmbientes[*]}; do
                                ssh $sServer $inifile $totvsdir/$sDir/appserver.ini $sEnv SourcePath $pastaapo/$pastanova
                        done
                done
         fi
  done

  echo -e "........................................"
  echo -e "... Atualizacao efetuada com sucesso ..."
  echo -e "........................................"

# FIM

