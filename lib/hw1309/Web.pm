package hw1309::Web;

use strict;
use warnings;
use utf8;
use Kossy;
use DBIx::Sunny;

sub dbh {
	my $self = shift;
	$self->{_dbh} ||= DBIx::Sunny->connect( "dbi:mysql:test",'root','1234',{
		Callbacks => {
			connected => sub {
				my $conn = shift;
				$conn->do(<<EOF);
CREATE TABLE IF NOT EXISTS t_history( input_text TEXT );
EOF
				return; 
			},
		},
	});
};

sub addDb {
    my $self = shift;
    my ( $input_text ) = @_;
    $self->dbh->query(
        q{INSERT INTO t_history (input_text) VALUES ( ? )},
        $input_text
    );
}

sub getDbList {
    my $self = shift;
    my $rows = $self->dbh->select_all(
        "SELECT * FROM t_history"
    );
    return $rows;
}

sub clearDbList {
    my $self = shift;
    $self->dbh->query(
        "DELETE FROM t_history"
#         "TRUNCATE TABLE"
    );
}

filter 'set_title' => sub {
    my $app = shift;
    sub {
        my ( $self, $c )  = @_;
        $c->stash->{site_name} = __PACKAGE__;
        $app->($self,$c);
    }
};

get '/' => sub {
    my ( $self, $c )  = @_;
    my $db_inputs = $self->getDbList();
    $c->render('index.tx', {
        db_inputs => $db_inputs,
    });
};

post '/input' => sub {
    my ( $self, $c )  = @_;
    my $result = $c->req->validator([
        'input1' => {
		    rule => [
                ['NOT_NULL','empty input1'],
            ],
        }
    ]);
    $self->addDb( $result->valid->get('input1') );
  	$c->render_json({ location => $c->req->uri_for("/")->as_string }); # send reload url
};

post '/delall' => sub {
    my ( $self, $c )  = @_;
    $self->clearDbList();
  	$c->render_json({ location => $c->req->uri_for("/")->as_string }); # send reload url
};

1;

