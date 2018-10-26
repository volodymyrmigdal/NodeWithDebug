(function _Preload_ss_() {

  'use strict';

  var inspector = require('inspector');
  require( 'wFiles' );
  var _ = _global_.wTools;

  if( !process.env.NODE_OPTIONS )
  process.env.NODE_OPTIONS = '';
  process.env.NODE_OPTIONS += ' --require ' + __filename;

  inspector.open( 0, undefined, false );
  let uri = _.uri.parse( inspector.url() );
  let port = Number( uri.port );
  var processInfoPath = _.path.join( __dirname, _.toStr( process.pid ) )
  var processInfo = { id : process.pid, debugPort : port, args : process.argv };
  inspector.close();
  process.on( 'exit', () => _.fileProvider.fileDelete( processInfoPath ) );
  _.fileProvider.fileWrite( processInfoPath, JSON.stringify( processInfo ) );
  inspector.open( port, undefined, true );
})();
