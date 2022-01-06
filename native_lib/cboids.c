#ifdef _WIN32
#	define WIN32_LEAN_AND_MEAN
#	include <Windows.h>
#	pragma comment(lib, "erts_MD.lib")
#endif

#include "erl_nif.h"

int add (int a, int b)
{
    return a + b;
}

__declspec(dllexport) ERL_NIF_TERM add_niff(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[])
{
	int a = 0;
    int b = 0;
    
    if (!enif_get_int(env, argv[0], &a)) {
        return enif_make_badarg(env);
    }
    if (!enif_get_int(env, argv[1], &b)) {
        return enif_make_badarg(env);
    }
    
    int result = add(a, b);
    return enif_make_int(env, result);
}

static ErlNifFunc nif_funcs[] =
{
	{"add", 2, add_niff}
};

ERL_NIF_INIT(Elixir.CBoids,nif_funcs,NULL,NULL,NULL,NULL)