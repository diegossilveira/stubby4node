Stubby = require('../src/main').Stubby
fs = require 'fs'
http = require 'http'
yaml = require 'js-yaml'
endpointData = yaml.load (fs.readFileSync 'spec/data/e2e.yaml', 'utf8').trim()

createRequest = (context) ->
   context.status ?= 200
   context.body ?= ''
   context.headers ?= {}
   options =
      host: 'localhost'
      port: '8882'
      method: context.method
      path: context.url
      headers: context.requestHeaders

   request = http.request options, (response) ->
      data = ''
      response.on 'data', (chunk) ->
         data += chunk
      response.on 'end', ->
         return unless data.trim() is context.body
         return unless response.statusCode is context.status

         for key, value of context.headers
            return unless value is response.headers[key]

         context.passed = true

   request.write context.post if context.post?
   request.end()

describe 'End 2 End Test Suite', ->
   sut = null
   context = null

   beforeEach ->
      sut = new Stubby()
      context = passed: false
      go = false

      sut.start data:endpointData, -> go = true
      waitsFor ( -> go ), 'stubby to start', 1000

   afterEach ->
      stopped = false
      sut.stop -> stopped = true
      waitsFor (-> stopped), 'stubby to stop', 10

   describe 'Stubs', ->
      describe 'basics', ->
        it 'should return a basic GET endpoint', ->
            context.url = '/basic/get'
            context.method = 'get'

            createRequest context
            waitsFor ( -> context.passed ), 'request to finish', 1000

        it 'should return a basic PUT endpoint', ->
            context.url = '/basic/put'
            context.method = 'put'

            createRequest context
            waitsFor ( -> context.passed ), 'request to finish', 1000

        it 'should return a basic POST endpoint', ->
            context.url = '/basic/post'
            context.method = 'post'

            createRequest context
            waitsFor ( -> context.passed ), 'request to finish', 1000

        it 'should return a basic DELETE endpoint', ->
            context.url = '/basic/delete'
            context.method = 'delete'

            createRequest context
            waitsFor ( -> context.passed ), 'request to finish', 1000

      describe 'GET', ->
        it 'should return a body from a GET endpoint', ->
            context.url = '/get/body'
            context.method = 'get'
            context.body = 'plain text'

            createRequest context
            waitsFor ( -> context.passed ), 'request to finish', 1000

        it 'should return a body from a json GET endpoint', ->
            context.url = '/get/json'
            context.method = 'get'
            context.body = '{"property":"value"}'
            context.headers =
               'content-type': 'application/json'

            createRequest context
            waitsFor ( -> context.passed ), 'request to finish', 1000

        it 'should return a 420 GET endpoint', ->
            context.url = '/get/420'
            context.method = 'get'
            context.status = 420

            createRequest context
            waitsFor ( -> context.passed ), 'request to finish', 1000

      describe 'post', ->
        it 'should be able to handle authorized posts', ->
            context.url = '/post/auth'
            context.method = 'post'
            context.status = 201
            context.post = 'some=data'
            context.requestHeaders =
               authorization: "Basic c3R1YmJ5OnBhc3N3b3Jk"
            context.headers =
               location: '/some/endpoint/id'
            context.body = 'resource has been created'

            createRequest context
            waitsFor ( -> context.passed ), 'request to finish', 1000
