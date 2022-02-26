sub send_mailgun_email {

    # Recipient is either an email address or a mailing list id
	my ($pgcontent,$pgtitle,$recipient) = @_;
	my $response;

    my $mailgun = &set_up_mailgun();
    my $res = &mailgun_message($mailgun,$recipient,$pgtitle,$pgcontent);

    return $res;
}


# Receives the response from the email, subscribes user, sends confirm email 
sub mailgun_subscribe_confirm {

    my ($email,$listid) = @_;

    my $mailgun = &set_up_mailgun();
    my $ml = $listid . '@' . $Site->{mailgun_domain};

    # add member
    my $res = $mailgun->add_list_member($ml => {
        address => 'user@example.com', # member address
        subscribed => 'yes',           # yes(default) or no
        upsert     => 'no',            # no (default). if yes, update existing member
    });

    &mailgun_message($mailgun,$email,"Subscription confirmed","You've been added to the $listid mailing list");

    return $res;

}

sub set_up_mailgun {

    # Set Up mailgun
    eval "use WebService::Mailgun";
    if ($@) { &status_error("WebService::Mailgun module is required to send MailGun email."); }
    unless ($Site->{mailgun_apikey} && $Site->{mailgun_domain}) {
        &status_error("Please define Mailgun API key and domain in Social:Accounts."); 
    }
    $Site->{mailgun_locale} ||= "US";
    my $mailgun = WebService::Mailgun->new(
        api_key => $Site->{mailgun_apikey},
        domain => $Site->{mailgun_domain},
        region => $Site->{mailgun_locale},
        RaiseError => 1,
    );
    return $mailgun;

}

sub mailgun_message {

    my ($mailgun,$recipient,$pgtitle,$pgcontent) = @_;
    # $recipient is either an email address (in which case it will contain an '@' or it is a listid)


    # To
    unless ($recipient =~ /@/) {
        unless ($recipient) { &status_error("Recipient is undefined."); }
        $recipient = lc($recipient) . '@' . $Site->{mailgun_domain};
    }

    # From
    my $from = $Site->{st_email}; 
    unless ($from) {  &status_error("Please define a site email address in Admin:General first"); }

    # Subject
    unless ($pgtitle) { $pgtitle = "No subject"; }

    # Body
    unless ($pgcontent) { &status_error("Email doesn't contain any content"); }


    my $res = $mailgun->message({
        from    => $from,
        to      => $recipient,
        subject => $pgtitle,
        html    => $pgcontent,
    });
    return $res;
}
1;