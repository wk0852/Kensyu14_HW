package hw1309::Web;

use strict;
use warnings;
use utf8;
use encoding 'utf8';
use Kossy;
use DBIx::Sunny;

use Data::Dumper;

my $tempEditId = -1;

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
	$self->dbh->query( q{INSERT INTO content (title, memo, priority, status, deadline) VALUES ( ?, ?, ?, 0, DATE_FORMAT(?,'%Y/%m/%d %H:%i:%s') )}, $title, $memo, $priority, $deadline );
}

sub updateDb {
    my $self = shift;
	my ( $id, $title, $memo, $priority, $status, $deadline ) = @_;
	$self->dbh->query( "UPDATE content SET title = '".$title."', memo = '".$memo."', priority = ".$priority.", status = ".$status.", deadline = DATE_FORMAT('".$deadline."','%Y/%m/%d %H:%i:%s') WHERE id = '".$id."';" );
}

sub getDbList {
    my $self = shift;
    my $rows = $self->dbh->select_all(
        "SELECT * FROM content"
    );
    return $rows;
}

sub getDbById {
    my $self = shift;
    my ( $id  ) = @_;
    my $rows = $self->dbh->select_all(
        q{SELECT * FROM content WHERE id = ?}
        , $id
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

get '/list' => sub {
    my ( $self, $c )  = @_;
    my $db_inputs = $self->getDbList();
   	$c->render_json({ db_inputs => $db_inputs }); # send reload url
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

post '/modify' => sub { # from edit form
    my ( $self, $c )  = @_;
    
    my $result = $c->req->validator([
        'edit_title' => {
		    rule => [
                ['NOT_NULL','empty title'],
            ],
        },
        'edit_memo' => {
		    rule => [
                ['NOT_NULL','empty memo'],
            ],
        },
        'edit_priority' => {
		    rule => [
                ['NOT_NULL','empty priority'],
            ],
        },
        'edit_status' => {
		    rule => [
                ['NOT_NULL','empty status'],
            ],
        },
        'edit_deadline' => {
		    rule => [
                ['NOT_NULL','empty deadline'],
            ],
        },
        'edit_id' => {
		    rule => [
                ['NOT_NULL','empty id'],
            ],
        },
    ]);
    $self->updateDb( $result->valid->get('edit_id'), $result->valid->get('edit_title'), $result->valid->get('edit_memo'), $result->valid->get('edit_priority'), $result->valid->get('edit_status'), $result->valid->get('edit_deadline') );
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

post '/edit' => sub {
    my ( $self, $c )  = @_;
    my $result = $c->req->validator([
        'id' => {
		    rule => [
                ['NOT_NULL','empty id'],
            ]
        }
    ]);

	$tempEditId = $result->valid->get('id');
   	$c->render_json({ location => $c->req->uri_for("/edit")->as_string }); # send reload url
#    	$c->render_json({ location => $c->req->uri_for("/edit?id=".$result->valid->get('id'))->as_string }); # send reload url
    
};

get '/edit' => sub {
    my ( $self, $c )  = @_;
    my $db_outputs = $self->getDbById( $tempEditId );

    $c->render('edit.tx', {
        db_outputs => $db_outputs,
        edit_id => $tempEditId,
    });    
};



1;

