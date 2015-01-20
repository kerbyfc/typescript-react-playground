<?php

use Vertx\Buffer;
$log = Vertx::logger();

$client = Vertx::createHttpClient()
  ->host('tm6.infowatch.ru')
  ->port(443)
  ->ssl(TRUE)
  ->trustAll(TRUE);

$client->getNow('/user/check', function($response) use ($log) {

  $body = new Buffer();

  $response->dataHandler(function($buffer) use ($log) {
    if ($body !== null) {
      $body->appendBuffer($buffer);
    } else {
      $log->info('No body');
    }
  });

  $response->endHandler(function() use ($log) {
    $log->info('The total body received was '. $buffer->length .' bytes.');
  });

});
