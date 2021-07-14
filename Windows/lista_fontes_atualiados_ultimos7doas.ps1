$fileList = Get-ChildItem -Path "D:\TOTVS12\Jenkins\workspace\s-production-git_protheus_master" -Recurse -include *.prw | ? {$_.LastWriteTime -gt (Get-Date).AddDays(-7)}
$cArquivosLST = '';
foreach($file in $fileList) {   
	 $aux = Get-Item $file | select -Property FullName
    Write-Host $aux.FullName 
    $cArquivosLST +=    $aux.FullName +";"

}
"$cArquivosLST" | out-file -filepath "D:\TOTVS12\Jenkins\workspace\s-production-git_protheus_master\lista_de_fontes_a_serem_compilados.lst"

