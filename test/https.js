const fs = require('fs')
const {resolve} = require('path')
const https = require('https')
const {format} = require('util')

const args = process.argv.slice(2)
const type = args[0] || 'star'
const port = args[1] || 8443

const certsDir = resolve(__dirname, '..')

const options = {
  key: fs.readFileSync(resolve(certsDir, type + '.key')),
  cert: fs.readFileSync(resolve(certsDir, type + '.crt'))
}

const server = https.createServer(options, (req, res) => {
  const {method, url, headers} = req
  const str = format(':%s %s %s %s\n  %s',
    port, method, url,
    Math.random().toString(16).substr(2),
    JSON.stringify(headers, null, 2).replace(/\n/g, '\n  ')
  )
  console.log(str)
  res.end(str + '\n')
})

server.listen(port, () => {
  console.log('running with "%s.crt" on :%s', type, port)
})
