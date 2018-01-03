const fs = require('fs')
const {resolve} = require('path')
const https = require('https')
const {format} = require('util')

const certsDir = resolve(__dirname, '../certs')

module.exports = setup

function setup (opts) {
  const {type, pfx} = opts

  const crtOptions = {
    key: fs.readFileSync(resolve(certsDir, type + '.key')),
    cert: fs.readFileSync(resolve(certsDir, type + '.crt'))
  }

  const pfxOptions = {
    pfx: fs.readFileSync(resolve(certsDir, type + '.pfx')),
    passphrase: fs.readFileSync(resolve(certsDir, type + '.pfx.pass'), 'utf8').trim()
  }

  const options = pfx ? pfxOptions : crtOptions

  const server = https.createServer(options, (req, res) => {
    const {method, url, headers} = req
    const str = format('%s %s %s\n  %s',
      method, url,
      Math.random().toString(16).substr(2),
      JSON.stringify(headers, null, 2).replace(/\n/g, '\n  ')
    )
    console.log(str)
    res.end(str + '\n')
  })

  return server
}

if (require.main === module) {
  let type = 'star'
  let port = 8443
  let pfx = false

  const args = process.argv.slice(2)
  while (args.length) {
    const arg = args.shift()
    if (/^\d+$/.test(arg)) {
      port = +arg
    } else if (/^(star|site)$/.test(arg)) {
      type = arg
    } else if (/^(pfx)$/.test(arg)) {
      pfx = true
    }
  }

  setup({type, pfx}).listen(port, () => {
    console.log('running with "%s.crt" on :%s %s', type, port, pfx ? 'using pfx certs' : '')
  })
}
