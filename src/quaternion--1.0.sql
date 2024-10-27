CREATE FUNCTION test_add(a int, b int)
RETURNS int
AS 'MODULE_PATHNAME', 'test_add'
LANGUAGE C STRICT IMMUTABLE PARALLEL SAFE;

CREATE TYPE quaternion;

CREATE FUNCTION quaternion_in(cstring)
    RETURNS quaternion
    AS 'MODULE_PATHNAME', 'quaternion_in'
    LANGUAGE C IMMUTABLE STRICT;

CREATE FUNCTION quaternion_out(quaternion)
    RETURNS cstring
    AS 'MODULE_PATHNAME', 'quaternion_out'
    LANGUAGE C IMMUTABLE STRICT;

CREATE FUNCTION quaternion_send(quaternion)
    RETURNS bytea
    AS 'MODULE_PATHNAME', 'quaternion_send'
    LANGUAGE C IMMUTABLE STRICT;

CREATE FUNCTION quaternion_recv(internal)
    RETURNS quaternion
    AS 'MODULE_PATHNAME', 'quaternion_recv'
    LANGUAGE C IMMUTABLE STRICT;

CREATE TYPE quaternion (
   internallength = 32,
   input = quaternion_in,
   output = quaternion_out,
   receive = quaternion_recv,
   send = quaternion_send,
   alignment = double
);
