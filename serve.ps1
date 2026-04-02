$port = if ($env:PORT) { [int]$env:PORT } else { 5000 }
$root = "C:\Users\ana.amaral\Desktop\Ana\Gerador de Propostas - HTML"
$listener = [System.Net.Sockets.TcpListener]::new([System.Net.IPAddress]::Loopback, $port)
$listener.Start()
[Console]::Out.WriteLine("Server started on http://localhost:$port/")
[Console]::Out.Flush()
while ($true) {
    $client = $listener.AcceptTcpClient()
    $stream = $client.GetStream()
    $reader = [System.IO.StreamReader]::new($stream)
    $reqLine = $reader.ReadLine()
    while ($reader.ReadLine() -ne '') {}
    $path = "/"
    if ($reqLine -match '^GET\s+(\S+)') { $path = $Matches[1].Split('?')[0] }
    if ($path -eq '/' -or $path -eq '') { $path = '/index.html' }
    $filePath = Join-Path $root $path.TrimStart('/').Replace('/', '\')
    if (Test-Path $filePath -PathType Leaf) {
        $bytes = [System.IO.File]::ReadAllBytes($filePath)
        $ct = switch -Wildcard ($filePath) {
            '*.html' { 'text/html; charset=utf-8' }
            '*.css'  { 'text/css' }
            '*.js'   { 'application/javascript' }
            '*.png'  { 'image/png' }
            default  { 'application/octet-stream' }
        }
        $header = "HTTP/1.1 200 OK`r`nContent-Type: $ct`r`nContent-Length: $($bytes.Length)`r`nConnection: close`r`n`r`n"
        $headerBytes = [System.Text.Encoding]::ASCII.GetBytes($header)
        $stream.Write($headerBytes, 0, $headerBytes.Length)
        $stream.Write($bytes, 0, $bytes.Length)
    } else {
        $resp = "HTTP/1.1 404 Not Found`r`nContent-Length: 0`r`nConnection: close`r`n`r`n"
        $b = [System.Text.Encoding]::ASCII.GetBytes($resp)
        $stream.Write($b, 0, $b.Length)
    }
    $stream.Flush()
    $client.Close()
}
