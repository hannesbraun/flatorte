# Flatorte

*A WebCal server for courses at the Offenburg University*

## Installation

Requirements:
- Crystal 1.2.0 (or later)
- Shards
- TheCitadelofRicks 1.3.0 (or later)

Use the following to build Flatorte:
```bash
shards build --release --no-debug
```

The executable will be located in the `bin` directory of this repository.

If you want to use TLS to encrypt connections, you can use Let's Encrypt with `certbot`.
Use something along the lines of the following to obtain your certificate:
```bash
certbot certonly -a standalone -d cool.domain.ai
```

## Usage

Flatorte can be started without any arguments. Traffic won't be encrypted in this case.

To specify the private key and the certificate chain, use the according parameters:
```bash
flatorte -k privkey.pem -c fullchain.pem
```

If you want to load some courses initially to get the first response faster, use the `--init` option:
```bash
flatorte --init INFM1,INFM2
```

For more information, see
```bash
flatorte --help
```

## Development

- Follow the official coding style and run `crystal tool format` before comitting.
- The server needs to keep sending responses fast. This is one of the main reasons for this service to exist.
- Be nice ;)

## Contributing

1. Fork it (<https://github.com/hannesbraun/flatorte/fork>)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## Contributors

- [Hannes Braun](https://github.com/hannesbraun) - creator and maintainer

Special thanks go out to Jannik aka Seil0 for providing [TheCitadelofRicks](https://git.mosad.xyz/Seil0/TheCitadelofRicks).

## License

Flatorte is licensed under the [GNU General Public License 3](LICENSE).
