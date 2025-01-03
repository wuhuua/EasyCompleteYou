from ECY import rpc
from ECY import utils
from ECY.debug import logger
from ECY_engines.all.fzf import plugin_base


class Operate(plugin_base.Plugin):
    """
    """
    def __init__(self, event_id):
        self.event_id = event_id

        self.items = []
        self.engine_name = 'Buffer'

    def RegKeyBind(self):
        return {
            'ctrl-t': self._open_in_new_tab,
            'ctrl-x': self._open_vertically,
            'enter': self._open_in_new_tab
        }

    def _open_in_new_tab(self, event):
        res = event['res']
        if res == {}:
            return
        rpc.DoCall('ClosePopupWindows2')
        rpc.DoCall('ECY#utils#OpenFile', [res['path'], 't'])

    def _open_vertically(self, event):
        res = event['res']
        if res == {}:
            return
        rpc.DoCall('ClosePopupWindows2')
        rpc.DoCall('ECY#utils#OpenFile', [res['path'], 'x'])

    def GetSource(self, event):
        params = event['params']

        buffers_list = rpc.DoCall('ECY#utils#GetBufferPath')
        add_list = []
        self.items = []
        for item in buffers_list:
            item = item.replace('\\', '/')
            name = utils.GetAbbr(item, add_list)
            add_list.append(name)
            self.items.append({'abbr': name, 'path': item})
        return self.items

    def Preview(self, event):
        res = event['res']
        if res == {}:
            return ''
        return utils.Highlight(file_path=res['path'])
