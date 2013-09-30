package hw1309::Web;

use strict;
use warnings;
use utf8;
use encoding 'utf8';
use Kossy;
use DBIx::Sunny;

sub dbh {
	my $self = shift;
	$self->{_dbh} ||= DBIx::Sunny->connect( "dbi:mysql:test",'root','1234',{
		Callbacks => {
			connected => sub {
				my $conn = shift;
				$conn->do(<<EOF);
CREATE TABLE IF NOT EXISTS content(
    id INTEGER PRIMARY KEY NOT NULL AUTO_INCREMENT,
    title VARCHAR(128) NOT NULL,
    memo TEXT,
    priority INTEGER NOT NULL,
    status INTEGER NOT NULL DEFAULT 0 ,
    deadline DATETIME NOT NULL
 );
EOF
				return; 
			},
		},
	});
};

sub addDb {
    my $self = shift;
    my ( $title, $memo, $priority, $deadline  ) = @_;
#      my $queryStr = q{INSERT INTO content (title, memo, priority, status, deadline) VALUES ( ?, ?, ?, 0, now() )}, $title, $memo, $priority;
#      $queryStr = Encode::encode("utf-8", $queryStr);
#      $self->dbh->query( $queryStr );
       $self->dbh->query( q{INSERT INTO content (title, memo, priority, status, deadline) VALUES ( ?, ?, ?, 0, now() )}, $title, $memo, $priority );
}

sub getDbList {
    my $self = shift;
    my $rows = $self->dbh->select_all(
        "SELECT * FROM content"
    );
    return $rows;
}

sub clearDbList {
    my $self = shift;
    $self->dbh->query(
        "DELETE FROM content"
    );
}
sub clearDbListOne {
    my $self = shift;
    my ( $id  ) = @_;
    $self->dbh->query(
        q{DELETE FROM content WHERE id = ?}
        , $id    
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

#     if( $db_inputs.priority == 0 )
#     	$db_inputs.priorityStr = "aa";
#     else if( $db_inputs.priority == 1 )
#     	$db_inputs.priorityStr = "bb";
#     else if( $db_inputs.priority == 2 )
#     	$db_inputs.priorityStr = "cc";
#     	
#     if( $db_inputs.status == 0 )
#     	$db_inputs.priorityStr = "新規";
#     else if( $db_inputs.status == 1 )
#     	$db_inputs.priorityStr = "済み";
    	
    $c->render('index.tx', {
        db_inputs => $db_inputs,
    });
};

post '/input' => sub {
    my ( $self, $c )  = @_;
    my $result = $c->req->validator([
        'title' => {
		    rule => [
                ['NOT_NULL','empty title'],
            ],
        },
        'memo' => {
		    rule => [
                ['NOT_NULL','empty memo'],
            ],
        },
        'priority' => {
		    rule => [
                ['NOT_NULL','empty priority'],
            ],
        },
        'status' => {
		    rule => [
                ['NOT_NULL','empty status'],
            ],
        },
        'deadline' => {
		    rule => [
                ['NOT_NULL','empty deadline'],
            ],
        }
    ]);
	$self->addDb( $result->valid->get('title'), $result->valid->get('memo'), $result->valid->get('priority'), $result->valid->get('deadline') );
   	$c->render_json({ location => $c->req->uri_for("/")->as_string }); # send reload url
};

post '/delall' => sub {
    my ( $self, $c )  = @_;
    $self->clearDbList();
  	$c->render_json({ location => $c->req->uri_for("/")->as_string }); # send reload url
};

post '/del' => sub {
    my ( $self, $c )  = @_;
    my $result = $c->req->validator([
        'id' => {
		    rule => [
                ['NOT_NULL','empty id'],
            ]
        }
    ]);
    $self->clearDbListOne($result->valid->get('id'));
  	$c->render_json({ location => $c->req->uri_for("/")->as_string }); # send reload url
};


1;

