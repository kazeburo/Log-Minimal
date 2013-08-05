requires 'Data::Dumper';
requires 'Scalar::Util';
requires 'Term::ANSIColor';

on test => sub {
    requires 'Test::More', '0.98';
};
