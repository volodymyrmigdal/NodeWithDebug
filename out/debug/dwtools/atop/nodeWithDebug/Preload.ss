(function _Preload_ss_() {

  'use strict';

  var inspector = require( 'inspector' );
  var ipc = require( 'node-ipc' );
  var deasync = require( 'deasync' );
  var url = require('url');

  ipc.config.id = process.pid;
  ipc.config.retry = 1000;
  ipc.config.silent = true;

  let currentState;

  let connectTo = deasyncEmptyCb( ipc, ipc.connectTo );
  connectTo( 'nodewithdebug' );
  let nodeWithDebug = ipc.of.nodewithdebug;
  let nodeWithDebugOn = deasyncEmptyCb( nodeWithDebug, nodeWithDebug.on );
  nodeWithDebugOn( 'connect' );
  nodeWithDebug.emit( 'currentStateGet', { id :  process.pid, message : process.pid } )
  nodeWithDebugOn( 'currentState' );

  let preload = ' --require ' + __filename;

  if( !currentState.debug )
  {
    process.env.NODE_OPTIONS = strReplaceAll( process.env.NODE_OPTIONS, preload, '' );
    ipc.disconnect( 'nodewithdebug' );
    return;
  }

  if( !process.env.NODE_OPTIONS )
  process.env.NODE_OPTIONS = '';
  process.env.NODE_OPTIONS = strAppendOnce( process.env.NODE_OPTIONS, preload )

  inspector.open( 0, undefined, false );

  let uri = url.parse( inspector.url() );

  let port = Number( uri.port );

  var processInfo = { id : process.pid, debugPort : port, args : process.argv };

  inspector.close();

  nodeWithDebug.emit( 'newNode', { id :  process.pid, message : processInfo } )

  nodeWithDebugOn( 'newNodeReady' );

  inspector.open( port, undefined, true );

  ipc.disconnect( 'nodewithdebug' );

/**/

function deasyncEmptyCb( context, routine )
{
  return function ()
  {
      let ready = false
      let args = Array.prototype.slice.apply( arguments ).concat( cb );
      let e = args[ 0 ];

      routine.apply( context, args );
      deasync.loopWhile( () => !ready )

      function cb( data )
      {
        if( e === 'currentState' )
        currentState = data.message;

        ready = true
      }
  }
}

 function strReplaceAll( str, search, replacement)
 {
   return str.replace(new RegExp( search, 'g' ), replacement );
 };

 function strAppendOnce( src,end )
 {
   if( src.indexOf( end, src.length - end.length ) !== -1 )
   return src;
   else
   return src + end;
 }

})();