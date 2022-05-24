from ECY_engines import lsp
from ECY import utils


class Operate(lsp.Operate):
    def __init__(self, engine_name):
        lsp.Operate.__init__(self,
                             engine_name,
                             languageId='python',
                             use_completion_cache=True,
                             use_completion_cache_position=True)