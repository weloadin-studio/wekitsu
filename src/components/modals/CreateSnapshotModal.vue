<template>
  <div
    :class="{
      modal: true,
      'is-active': active
    }"
  >
    <div class="modal-background" @click="cancel"></div>

    <div class="modal-content">
      <div class="box">
        <h1 class="title">
          {{ $t('snapshots.create_title', 'Create Snapshot') }}
        </h1>

        <div class="field">
          <label class="label">{{ $t('snapshots.type', 'Type') }}</label>
          <div class="control">
            <div class="select is-fullwidth">
              <select v-model="form.type">
                <option value="source">Source</option>
                <option value="exports">Exports</option>
              </select>
            </div>
          </div>
        </div>

        <div class="field">
          <label class="label">{{ $t('snapshots.thumbnail', 'Thumbnail') }}</label>
          <div v-if="form.thumbnailPath" class="media-preview-box">
            <img :src="previewUrls.thumbnail" class="preview-media" />
            <br />
            <button class="button is-danger is-small mt-2" @click="removeMedia('thumbnail')">Remove</button>
          </div>
          <file-upload
            v-else
            ref="thumbnailUpload"
            :label="$t('snapshots.select_thumbnail', 'Select Thumbnail')"
            accept="image/*"
            :multiple="false"
            @fileselected="onThumbnailSelected"
          />
        </div>

        <div class="field">
          <label class="label">{{ $t('snapshots.preview', 'Preview (Video)') }}</label>
          <div v-if="form.previewPath" class="media-preview-box">
            <video :src="previewUrls.preview" class="preview-media" controls></video>
            <br />
            <button class="button is-danger is-small mt-2" @click="removeMedia('preview')">Remove</button>
          </div>
          <file-upload
            v-else
            ref="previewUpload"
            :label="$t('snapshots.select_preview', 'Select Preview')"
            accept="video/*"
            :multiple="false"
            @fileselected="onPreviewSelected"
          />
        </div>

        <div class="field">
          <label class="label">{{ $t('snapshots.message', 'Message') }}</label>
          <div class="control">
            <textarea
              class="textarea"
              v-model="form.message"
              :placeholder="$t('snapshots.message_placeholder', 'Enter a description...')"
            ></textarea>
          </div>
        </div>
        
        <p class="help is-info" v-if="isProcessing">
          {{ processingMessage }}
        </p>
        <p class="error has-text-danger" v-if="isError">
          {{ $t('snapshots.create_error', 'Error creating snapshot') }}
        </p>

        <div class="field is-grouped is-grouped-right mt-4">
          <div class="control">
             <button @click="cancel" class="button" :disabled="isLoading || isProcessing">
              {{ $t('main.cancel', 'Cancel') }}
            </button>
          </div>
          <div class="control">
            <button
              class="button is-primary"
              :class="{ 'is-loading': isLoading }"
              @click="submitSnapshot"
              :disabled="isLoading || isProcessing"
            >
              {{ $t('snapshots.create_btn', 'Snapshot') }}
            </button>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import { modalMixin } from '@/components/modals/base_modal'
import FileUpload from '@/components/widgets/FileUpload.vue'

export default {
  name: 'create-snapshot-modal',

  mixins: [modalMixin],

  components: {
    FileUpload
  },

  props: {
    active: {
      type: Boolean,
      default: false
    },
    taskId: {
      type: String,
      required: true
    }
  },

  emits: ['cancel', 'confirm'],

  data() {
    return {
      form: {
        type: 'source',
        message: '',
        thumbnailPath: null,
        previewPath: null
      },
      previewUrls: {
        thumbnail: null,
        preview: null
      },
      isLoading: false,
      isError: false,
      isProcessing: false,
      processingMessage: ''
    }
  },

  methods: {
    async processMediaFile(file, type) {
      if (!file) return null;

      // Get the native filesystem path via Electron's webUtils
      let filePath = null;
      if (window.electronAPI && window.electronAPI.getPathForFile) {
        filePath = window.electronAPI.getPathForFile(file);
      }
      if (!filePath) {
        console.error(`Cannot get native path for ${type} file`);
        return null;
      }
      
      this.isProcessing = true;
      this.processingMessage = `Processing ${type}... Please wait.`;
      
      try {
        if (window.electronAPI && window.electronAPI.processMedia) {
          const res = await window.electronAPI.processMedia(filePath, type);
          if (res && res.success) {
            return res.processedPath;
          } else {
            console.error(`Error processing ${type}:`, res?.error);
            this.isError = true;
          }
        }
      } catch (e) {
        console.error(`Exception processing ${type}:`, e);
        this.isError = true;
      } finally {
        this.isProcessing = false;
        this.processingMessage = '';
      }
      return null;
    },

    async onThumbnailSelected(formData, rawFile) {
      const file = rawFile || (formData && formData.get ? formData.get('file') : null);
      if (file) {
        if (this.previewUrls.thumbnail) URL.revokeObjectURL(this.previewUrls.thumbnail);
        this.previewUrls.thumbnail = URL.createObjectURL(file);
        this.form.thumbnailPath = await this.processMediaFile(file, 'thumbnail');
      }
    },

    async onPreviewSelected(formData, rawFile) {
      const file = rawFile || (formData && formData.get ? formData.get('file') : null);
      if (file) {
        if (this.previewUrls.preview) URL.revokeObjectURL(this.previewUrls.preview);
        this.previewUrls.preview = URL.createObjectURL(file);
        this.form.previewPath = await this.processMediaFile(file, 'preview');
      }
    },

    async removeMedia(type) {
      if (type === 'thumbnail' && this.form.thumbnailPath) {
        if (window.electronAPI && window.electronAPI.cleanupMedia) {
          await window.electronAPI.cleanupMedia([this.form.thumbnailPath]);
        }
        this.form.thumbnailPath = null;
        if (this.previewUrls.thumbnail) {
          URL.revokeObjectURL(this.previewUrls.thumbnail);
          this.previewUrls.thumbnail = null;
        }
        if (this.$refs.thumbnailUpload) this.$refs.thumbnailUpload.reset();
      } else if (type === 'preview' && this.form.previewPath) {
        if (window.electronAPI && window.electronAPI.cleanupMedia) {
          await window.electronAPI.cleanupMedia([this.form.previewPath]);
        }
        this.form.previewPath = null;
        if (this.previewUrls.preview) {
          URL.revokeObjectURL(this.previewUrls.preview);
          this.previewUrls.preview = null;
        }
        if (this.$refs.previewUpload) this.$refs.previewUpload.reset();
      }
    },

    async cancel() {
      const pathsToClean = [];
      if (this.form.thumbnailPath) pathsToClean.push(this.form.thumbnailPath);
      if (this.form.previewPath) pathsToClean.push(this.form.previewPath);
      
      if (pathsToClean.length > 0 && window.electronAPI && window.electronAPI.cleanupMedia) {
        await window.electronAPI.cleanupMedia(pathsToClean);
      }
      
      this.$emit('cancel');
      this.reset();
    },

    async submitSnapshot() {
      this.isLoading = true
      this.isError = false
      
      try {
        if (window.electronAPI && window.electronAPI.submitSnapshot) {
          const response = await window.electronAPI.submitSnapshot({
            taskId: this.taskId,
            type: this.form.type,
            message: this.form.message,
            thumbnailPath: this.form.thumbnailPath,
            previewPath: this.form.previewPath
          })

          if (response && response.success) {
            this.$emit('confirm')
            this.reset()
          } else {
            this.isError = true
            console.error('Snapshot creation failed:', response?.error)
          }
        } else {
          console.error('electronAPI.submitSnapshot is not available')
          this.isError = true
        }
      } catch (e) {
        console.error('Error creating snapshot:', e)
        this.isError = true
      } finally {
        this.isLoading = false
      }
    },

    reset() {
      this.form = {
        type: 'source',
        message: '',
        thumbnailPath: null,
        previewPath: null
      }
      if (this.previewUrls.thumbnail) {
        URL.revokeObjectURL(this.previewUrls.thumbnail)
        this.previewUrls.thumbnail = null
      }
      if (this.previewUrls.preview) {
        URL.revokeObjectURL(this.previewUrls.preview)
        this.previewUrls.preview = null
      }
      this.isError = false
      this.isLoading = false
      this.isProcessing = false
      this.processingMessage = ''
      // Reset file inputs
      if (this.$refs.thumbnailUpload) this.$refs.thumbnailUpload.reset()
      if (this.$refs.previewUpload) this.$refs.previewUpload.reset()
    }
  },

  watch: {
    active(newVal) {
      if (newVal) {
        this.reset()
      }
    }
  }
}
</script>

<style lang="scss" scoped>
.modal-content {
  width: 600px;
}
.media-preview-box {
  padding: 10px;
  border: 1px solid #dbdbdb;
  border-radius: 6px;
  text-align: center;
  background: #fcfcfc;
}
:global(.dark) .media-preview-box {
  background: #2f3136;
  border-color: #40444b;
}
.preview-media {
  max-width: 100%;
  max-height: 250px;
  border-radius: 4px;
}
</style>
