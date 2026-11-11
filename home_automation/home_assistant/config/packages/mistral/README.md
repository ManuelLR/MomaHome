# Mistral AI → Home Assistant (Assist)

Custom integration [SnarfNL/HA_MistralAI](https://github.com/SnarfNL/HA_MistralAI)
(domain `mistral_conversation`), installed in the image by the `Dockerfile`
(`CUSTOM_COMPONENT_MISTRAL_CONVERSATION_VERSION`, tracked by Renovate).
Unofficial: no Mistral integration exists in HA core.

It provides:
- **Conversation agent** for Assist (device control through the Assist API).
- **STT** with Voxtral and **TTS** with Mistral voices (optional).
- An `ai_task` entity.

No YAML here: it is configured from the UI only, and the API key lives in
`.storage` (not in `secrets.yaml`).

## Setup

1. Create an API key at https://console.mistral.ai/ → *API Keys*.
2. Rebuild/restart the container so the component is in the image.
3. *Settings → Devices & services → Add integration → Mistral AI Conversation*,
   paste the key.
4. In the integration options pick the model and enable
   **Control Home Assistant** (Assist API).
5. *Settings → Voice assistants*: create/edit an assistant and select
   *Mistral AI* as conversation agent (and Voxtral / Mistral TTS if wanted).
   Enable *Prefer handling commands locally* to keep simple commands off the API.

To roll back, delete the integration from the UI and remove the block from the
`Dockerfile`.
