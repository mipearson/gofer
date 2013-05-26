# Revision History

### v0.3.1

 * Prefix stderr/stdout per host with `:output_prefix`

### v0.3.0

 * Add cluster support via `Gofer::Cluster` (@rich0h)

### v0.2.6 30/08/2012

 * Preserve options on file upload/download
 * Include host & server response in `Gofer::HostError` exceptions

### v0.2.5 02/06/2011

 * `#exists?` -> `#exist?` to be consistent with `File.exist?`

### v0.2.4 24/05/2011

 * Add `:quiet` as an option on `Gofer::Host` instantiation

### v0.2.3 21/05/2011

 * Add `write` command to `Gofer::Host`

### v0.2.2 10/05/20011

 * Add `run_multiple` method to `Gofer::Host`

### v0.2.1 08/05/2011

 * Add `quiet=` to Host instance to allow setting quiet to be the default.

### v0.2.0 03/05/2011

 * Flip ordering of username/hostname on instantiation to match that of `Net::SSH`

### v0.1.2 03/05/2011

 * Pass through `Gofer::Host` instantiation options straight through to `Net::SSH`.

### v0.1.1 23/04/2011

 * Minimal RDoc added.

### v0.1.0 20/04/2011

 * Replace string return from run with a 'response' object
 * Removed 'within' functionality - will be replaced by 'open' later

### v0.0.1 03/04/2011

 * Initial release
