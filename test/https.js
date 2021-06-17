#!/usr/bin/env node

const fs = require('fs')
const {resolve} = require('path')
const https = require('https')
const {format} = require('util')

const certsDir = resolve(__dirname, '../certs')

module.exports = setup

function setup (opts) {
  const {type, pfx} = opts

  const read = (filename, enc, supress) => {
    try {
      return fs.readFileSync(resolve(certsDir, filename), enc)
    } catch (e) {
      !supress && console.error(e.message)
    }
  }

  const crtOptions = {
    key: read(type + '.key'),
    cert: read(type + '.crt'),
    ca: [
      read('intermediate.crt', undefined, true),
      read('root_ca.crt')
    ].filter(Boolean)
  }

  const pfxOptions = {
    pfx: read(type + '.pfx'),
    passphrase: read(type + '.pfx.pass', 'utf8').trim()
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
    } else if (/^(pfx)$/.test(arg)) {
      pfx = true
    } else {
      type = arg
    }
  }

  setup({type, pfx}).listen(port, () => {
    console.log('running with "%s.crt" on :%s %s', type, port, pfx ? 'using pfx certs' : '')
  })
}
