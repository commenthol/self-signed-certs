const assert = require('assert')
const fs = require('fs')
const {parse} = require('url')
const https = require('https')
const setup = require('./https')

const PORT = 8443
const rootCA = fs.readFileSync(`${__dirname}/../certs/root_ca.crt`)

const assertErr = (err) => assert.ok(!err, err && err.message)
const assertStatus = (res) => assert.equal(res.statusCode, 200)

describe('Certificates', function () {
  it('star', function (done) {
    test({type: 'star'}, `https://localhost:${PORT}`, done)
  })

  it('star pfx', function (done) {
    test({type: 'star', pfx: true}, `https://localhost:${PORT}`, done)
  })

  it('site', function (done) {
    test({type: 'site'}, `https://aa.aa:${PORT}`, done)
  })

  it('site pfx', function (done) {
    test({type: 'site', pfx: true}, `https://aa.aa:${PORT}`, done)
  })
})

function test (serverOpts, url, done) {
  const server = setup(serverOpts).listen(PORT, (err) => {
    assertErr(err)
    request(url, (err, res) => {
      assertErr(err)
      assertStatus(res)
      server.close(done)
    })
  })
}
/**
* simple https request
*/
function request (url, cb) {
  const opts = parse(url)
  opts.method = 'GET'
  opts.ca = rootCA

  const req = https.request(opts, (res) => {
    let data = ''
    res.setEncoding('utf8')
    res.on('data', (chunk) => {
      data += chunk
    })
    res.on('error', (err) => {
      res.emit('end', err)
    })
    res.once('end', (err) => {
      res.body = data
      cb(err, res)
    })
  })
  req.on('error', (err) => {
    cb(err)
  })
  req.end()
}

/**
* poor mans mocha - bails out on first error
*/
function describe (name, fn) {
  this.tests = []
  fn.call(this)

  let length = 0

  run()

  function run () {
    const {fn, name} = this.tests[length++] || {}
    if (fn) {
      if (fn.length) { // async
        fn(done.bind(fn, name))
      } else { // sync
        fn()
        done(name)
      }
    }
  }

  function done (name) {
    console.log('--- ' + name + ' ---')
    process.nextTick(run)
  }
}

function it (name, fn) {
  this.tests.push({name, fn})
}

