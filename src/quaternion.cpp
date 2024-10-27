extern "C" {
#include <postgres.h>
#include <fmgr.h>

#include <lib/stringinfo.h>
#include <libpq/pqformat.h>
#include <nodes/execnodes.h>
#include <utils/builtins.h>

#include <server/funcapi.h>
}

import simple;

extern "C" {

PG_MODULE_MAGIC;

PG_FUNCTION_INFO_V1(test_add);
Datum test_add(PG_FUNCTION_ARGS) {
  auto a = PG_GETARG_UINT32(0);
  auto b = PG_GETARG_UINT32(1);
  PG_RETURN_INT32(Add(a, b));
}

PG_FUNCTION_INFO_V1(quaternion_in);

Datum quaternion_in(PG_FUNCTION_ARGS) {
  char *str = PG_GETARG_CSTRING(0);
  double a, b, c, d;
  Quaternion *result;

  if (sscanf(str, " ( %lf , %lf , %lf , %lf )", &a, &b, &c, &d) != 4)
    ereport(ERROR,
            (errcode(ERRCODE_INVALID_TEXT_REPRESENTATION),
             errmsg("invalid input syntax for quaternion: \"%s\"", str)));

  result = (Quaternion *)palloc(sizeof(Quaternion));
  result->a_ = a;
  result->b_ = b;
  result->c_ = c;
  result->d_ = d;
  PG_RETURN_POINTER(result);
}

PG_FUNCTION_INFO_V1(quaternion_out);

Datum quaternion_out(PG_FUNCTION_ARGS) {
  auto *quat = (Quaternion *)PG_GETARG_POINTER(0);
  char *result =
      psprintf("(%g,%g,%g,%g)", quat->a_, quat->b_, quat->c_, quat->d_);
  PG_RETURN_CSTRING(result);
}

PG_FUNCTION_INFO_V1(quaternion_recv);

Datum quaternion_recv(PG_FUNCTION_ARGS) {
  auto *buf = (StringInfo)PG_GETARG_POINTER(0);
  Quaternion *result;

  result = (Quaternion *)palloc(sizeof(Quaternion));
  result->a_ = pq_getmsgfloat8(buf);
  result->b_ = pq_getmsgfloat8(buf);
  result->c_ = pq_getmsgfloat8(buf);
  result->d_ = pq_getmsgfloat8(buf);
  PG_RETURN_POINTER(result);
}

PG_FUNCTION_INFO_V1(quaternion_send);

Datum quaternion_send(PG_FUNCTION_ARGS) {
  auto *quat = (Quaternion *)PG_GETARG_POINTER(0);
  StringInfoData buf;

  pq_begintypsend(&buf);
  pq_sendfloat8(&buf, quat->a_);
  pq_sendfloat8(&buf, quat->b_);
  pq_sendfloat8(&buf, quat->c_);
  pq_sendfloat8(&buf, quat->d_);
  PG_RETURN_BYTEA_P(pq_endtypsend(&buf));
}
}