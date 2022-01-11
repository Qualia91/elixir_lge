#ifdef _WIN32
#	define WIN32_LEAN_AND_MEAN
#	include <Windows.h>
#	pragma comment(lib, "erts_MD.lib")
#endif

#include "erl_nif.h"

__declspec(dllexport) ERL_NIF_TERM run(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[])
{
	int a = 0;
    int b = 0;
    
    if (!enif_get_int(env, argv[0], &a)) {
        return enif_make_badarg(env);
    }
    if (!enif_get_int(env, argv[1], &b)) {
        return enif_make_badarg(env);
    }
    
    int result = a + b;
    
    return enif_make_tuple2(env, enif_make_int(env, result), enif_make_string(env, "hello", ERL_NIF_LATIN1));
}

static ErlNifFunc nif_funcs[] =
{
	{"run", 2, run}
};

ERL_NIF_INIT(Elixir.CSystem,nif_funcs,NULL,NULL,NULL,NULL)