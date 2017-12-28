not( X ) :- X, !, fail.
not( _ ).

print_time( Hoursonly ) :-
    Minsonly is floor( Hoursonly * 60 ),
    Hours is Minsonly // 60,
    Mins is Minsonly mod 60,
    print_2digits( Hours ),
    print( ':' ),
    print_2digits( Mins ).

findpath( End, End, _, [End], 0, 0).
findpath( Curr, End, Visited, [[Curr, DepTime, ArrTime] | List], 
        CHour, CMin) :-

    flight(Curr, End, time(BHour, BMin) ),
    not( member( End, Visited ) ),
    can_board(BHour, BMin, CHour, CMin),
    track_time(Curr, End, NHour, NMin),
    DepTime is BHour + BMin / 60,
    ArrTime is NHour + NMin / 60,
    ArrTime < 24.0,
    findpath(End, End, [End | Visited], List, NHour, NMin).

haversine_radians(Lat1, Lon1, Lat2, Lon2, Distance) :-
    Dlon is Lon2 - Lon1,
    Dlat is Lat2 - Lat1,
    A is sin(Dlat/2) ** 2 
        + cos(Lat1) * cos(Lat2) * sin(Dlon/2) ** 2,
    Dist is 2 * atan2(sqrt(A), sqrt(1-A)),
    Distance is Dist * 3961.

can_board(BHour, BMin, CHour, CMin) :-
    BTime is (BHour * 100) + BMin,
    CTime is (CHour * 100) + CMin,
    CTime =< BTime.

track_time(PortA, PortB, NH, NM) :-
    flight(PortA, PortB, time(DH, DM)),
    flight_distance(PortA, PortB, Dist),
    travel_time(Dist, TH, TM),
    update_time(DH, DM, TH, TM, NH, NM).

flight_distance(X, Y, Distance) :-
    flight(X, Y, Time),
    airport(X, Xname, degmin(Deg1, Min1), degmin(Deg2, Min2)),
    airport(Y, Yname, degmin(Deg3, Min3), degmin(Deg4, Min4)),
    Lat1 is ((Min1 / 60) + Deg1) * pi / 180,
    Lon1 is ((Min2 / 60) + Deg2) * pi / 180,
    Lat2 is ((Min3 / 60) + Deg3) * pi / 180,
    Lon2 is ((Min4 / 60) + Deg4) * pi / 180,
    haversine_radians(Lat1, Lon1, Lat2, Lon2, Distance).

travel_time(Distance, Hours, Minutes) :-
    Time is Distance / 500,
    Hours is floor(Time),
    Minutes is floor((Time - Hours) * 60).

update_time(DepHour, DepMin, TravHour, TravMin, NewHour, NewMin) :-
    SomeHour is DepHour + TravHour,
    SomeMin is DepMin + TravMin + 30,
    X is SomeMin / 60,
    Y is floor(X),
    NewHour is SomeHour + Y,
    NewMin is SomeMin mod 60.

/*
* Write the given list using a certain form given departs/arrives
* paired with times.
*/
writepath( [] ) :-
    nl.
writepath( [[Dep, DDTime, DATime], Arr | []] ) :-
    airport( Dep, Depart_name, _, _),
    airport( Arr, Arrive_name, _, _),
    write( '     ' ), write( 'depart  ' ),
    write( Dep ), write( '  ' ),
    write( Depart_name ),
    print_time( DDTime ), nl,

    write( '     ' ), write( 'arrive  ' ),
    write( Arr ), write( '  ' ),
    write( Arrive_name ),
    print_time( DATime ), nl,
    !, true.
writepath( [[Dep, DDTime, DATime], [Arr, ADTime, AATime] | Rest] ) :-
    airport( Dep, Depart_name, _, _),
    airport( Arr, Arrive_name, _, _),
    write( '     ' ), write( 'depart  ' ),
    write( Dep ), write( '  ' ),
    write( Depart_name ),
    print_time( DDTime ), nl,

    write( '     ' ), write( 'arrive  ' ),
    write( Arr ), write( '  ' ),
    write( Arrive_name ),
    print_time( DATime ), nl,
    !, writepath( [[Arr, ADTime, AATime] | Rest] ).

/*
* Error if there is a flight where the departure and destination
* are one in the same.
*/

fly( Depart, Depart ) :-
    write( 'Error: the departure and the destination are the same.' ),
    nl,
    !, fail.

/*
* Main case.
*/
fly( Depart, Arrive ) :-
    airport( Depart, _, _, _ ),
    airport( Arrive, _, _, _ ),

    findpath( Depart, Arrive, [Depart], List, 0, 0),
    !, nl,
    writepath( List ),
    true.

/*
* Print error if the flight specified does not follow the rules of
* the twilight zone or if the airports do not exist.
*/
fly( Depart, Arrive ) :-
    airport( Depart, _, _, _ ),
    airport( Arrive, _, _, _ ),
    write( 'Error: your flight is not possible in the twilight zone.' ),
    !, fail.
fly( _, _) :-
    write( 'Error: nonexistent airport(s).' ), nl,
    !, fail.
