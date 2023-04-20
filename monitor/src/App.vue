<script setup>
import { ref, reactive } from 'vue';
import * as vNG from 'v-network-graph';
import { VNetworkGraph } from 'v-network-graph';
// import {
//   ForceLayout,
//   ForceNodeDatum,
//   ForceEdgeDatum,
// } from 'v-network-graph/lib/force-layout';

const CURRENT_URL = 'http://localhost:8080';
const isCurrentOnline = ref(false);
const currentIp = ref('');
const peers = ref([]);
const lastUpdate = ref(new Date());

const nodes = ref({
  // node1: { name: 'Node 1' },
});

const edges = ref({
  // edge1: { source: 'node1', target: 'node2' },
});

const layouts = ref({
  nodes: {
    // node1: { x: 0, y: 0 },
  },
});

const configs = reactive(
  vNG.defineConfigs({
    view: {
      scalingObjects: true,
      minZoomLevel: 0.1,
      maxZoomLevel: 16,
    },
  })
);

const isOnline = async (url) => {
  try {
    const res = await fetch(url, { method: 'HEAD' });
    return res.status === 200;
  } catch (err) {
    return false;
  }
};

const getData = async (url) => {
  const res = await fetch(url);

  return await res.text();
};

const processRaw = (raw) => {
  const lines = raw.split('\n').filter((i) => i.trim());
  const serverIp = lines[0].split(':')[1].trim();
  const memory = lines[2].split(':')[1]?.trim();

  const peers = lines
    .slice(3)
    .map((line) => line.split(','))
    .map((arr) => ({
      id: arr[0],
      ip: `10.0.0.${arr[0]}`,
      isOnline: false,
      key: arr[1],
    }));

  return {
    serverIp,
    peers,
    memory,
  };
};

const validate = async (peer) => {
  const peerUrl = `http://${peer.ip}:8080`;
  peer.isOnline = await isOnline(peerUrl);

  if (peer.isOnline) {
    const data = processRaw(await getData(peerUrl));
    peer.memory = data.memory;
  }

  return peer;
};

const syncData = async () => {
  isCurrentOnline.value = await isOnline(CURRENT_URL);

  if (isCurrentOnline.value) {
    const raw = await getData(CURRENT_URL);
    const data = processRaw(raw);

    currentIp.value = data.serverIp;
    peers.value = await Promise.all(data.peers.map(validate));

    nodes.value = {};
    edges.value = {};
    layouts.value = { nodes: {} };
    let nextX = ((80 * peers.value.length) / 2) * -1;
    for (const peer of peers.value) {
      nodes.value[peer.ip] = { name: peer.ip };

      if (peer.ip === '10.0.0.1') {
        layouts.value.nodes[peer.ip] = { x: 0, y: -80 };
        continue;
      }

      nextX += 80;
      edges.value[peer.ip] = { source: peer.ip, target: '10.0.0.1' };
      layouts.value.nodes[peer.ip] = { x: nextX, y: 0 };
    }

    lastUpdate.value = new Date();
  }

  setTimeout(() => {
    syncData();
  }, 1000);
};

syncData();
</script>

<template>
  <div class="p-4">
    <div
      v-if="!isCurrentOnline"
      class="text-center p-2 bg-red-100 border border-red-500 rounded text-red-800 mb-4"
    >
      Local Device Server is Offline
    </div>

    <table class="table w-full">
      <thead>
        <th class="border border-gray-400 px-3 py-2">Local Ip</th>
        <th class="border border-gray-400 px-3 py-2">Status</th>
        <th class="border border-gray-400 px-3 py-2">Public Key</th>
        <th class="border border-gray-400 px-3 py-2">Memory</th>
      </thead>

      <tbody>
        <tr
          v-for="peer in peers"
          :key="peer.ip"
          :class="`${currentIp === peer.ip ? 'bg-purple-100' : ''}`"
        >
          <td class="border border-gray-400 px-3 py-2">{{ peer.ip }}</td>
          <td class="border border-gray-400 px-3 py-2 text-center">
            <div
              class="border border-green-500 bg-green-100 text-green-800 px-2 py-1 rounded inline-block mr-2"
              v-if="peer.isOnline"
            >
              Online
            </div>
            <div
              class="border border-red-500 bg-red-100 text-red-800 px-2 py-1 rounded inline-block mr-2"
              v-else
            >
              Offline
            </div>
          </td>
          <td class="border border-gray-400 px-3 py-2">{{ peer.key }}</td>
          <td class="border border-gray-400 px-3 py-2">{{ peer.memory }}</td>
        </tr>
      </tbody>
    </table>

    <div class="mt-4 text-xs italic">Last Update: {{ lastUpdate }}</div>

    <div>
      <VNetworkGraph
        class="w-full h-[300px]"
        :nodes="nodes"
        :edges="edges"
        :configs="configs"
        :layouts="layouts"
      />
    </div>
  </div>
</template>
