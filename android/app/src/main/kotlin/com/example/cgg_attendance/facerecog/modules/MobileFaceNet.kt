package com.example.cgg_attendance.facerecog.modules

import android.content.res.AssetManager
import android.graphics.Bitmap
import org.tensorflow.lite.Interpreter
import java.io.FileInputStream
import java.nio.MappedByteBuffer
import java.nio.channels.FileChannel
import kotlin.math.max
import kotlin.math.pow
import kotlin.math.sqrt

class MobileFaceNet(assetManager: AssetManager?) {
    private val interpreter: Interpreter

    init {
        val options = Interpreter.Options()
        options.numThreads = 4
        interpreter = Interpreter(loadModelFile(assetManager!!), options)
    }
    private fun loadModelFile(assetManager: AssetManager): MappedByteBuffer {
        val fileDescriptor = assetManager.openFd(MODEL_FILE)
        val inputStream = FileInputStream(fileDescriptor.fileDescriptor)
        val fileChannel = inputStream.channel
        val startOffset = fileDescriptor.startOffset
        val declaredLength = fileDescriptor.declaredLength
        return fileChannel.map(FileChannel.MapMode.READ_ONLY, startOffset, declaredLength)
    }
    fun compare(bitmap1: Bitmap?, bitmap2: Bitmap?): Float {
        //Resize the face to 112X112, because the shape of the placeholder required for feed data below is (2, 112, 112, 3)
        val bitmapScale1 =
            Bitmap.createScaledBitmap(bitmap1!!, INPUT_IMAGE_SIZE, INPUT_IMAGE_SIZE, true)
        val bitmapScale2 =
            Bitmap.createScaledBitmap(bitmap2!!, INPUT_IMAGE_SIZE, INPUT_IMAGE_SIZE, true)
        val datasets = getTwoImageDatasets(bitmapScale1, bitmapScale2)
        val embeddings = Array(2) { FloatArray(192) }
        interpreter.run(datasets, embeddings)
        l2Normalize(embeddings, 1e-10)
        return evaluate(embeddings)
    }

    private fun evaluate(embeddings: Array<FloatArray>): Float {
        val embeddings1 = embeddings[0]
        val embeddings2 = embeddings[1]
        var dist = 0f
        for (i in 0..191) {
            //  dist += (embeddings1[i] - embeddings2[i]).pow(2.0) as Float
            dist += (embeddings1[i] - embeddings2[i]).toDouble().pow(2.0).toFloat()
        }
        var same = 0f
        for (i in 0..399) {
            val threshold = 0.01f * (i + 1)
            if (dist < threshold) {
                same += (1.0 / 400).toFloat()
            }
        }
        return same
    }

    private fun getTwoImageDatasets(
        bitmap1: Bitmap,
        bitmap2: Bitmap
    ): Array<Array<Array<FloatArray>>> {
        val bitmaps = arrayOf(bitmap1, bitmap2)
        val ims = intArrayOf(bitmaps.size, INPUT_IMAGE_SIZE, INPUT_IMAGE_SIZE, 3)
        val datasets = Array(ims[0]) {
            Array(
                ims[1]
            ) { Array(ims[2]) { FloatArray(ims[3]) } }
        }
        for (i in 0 until ims[0]) {
            val bitmap = bitmaps[i]
            datasets[i] = normalizeImage(bitmap)
        }
        return datasets
    }

    companion object {
        private const val MODEL_FILE = "MobileFaceNet.tflite"
        const val INPUT_IMAGE_SIZE =
            112 // The image width and height of the placeholder that requires feed data
        const val THRESHOLD =
            0.75f // Set a threshold value. If the value is greater than this value, it is considered to be the same person.

        fun normalizeImage(bitmap: Bitmap): Array<Array<FloatArray>> {
            val h = bitmap.height
            val w = bitmap.width
            val floatValues = Array(h) { Array(w) { FloatArray(3) } }
            val imageMean = 127.5f
            val imageStd = 128f
            val pixels = IntArray(h * w)
            bitmap.getPixels(pixels, 0, bitmap.width, 0, 0, w, h)
            for (i in 0 until h) { // 注意是先高后宽
                for (j in 0 until w) {
                    val `val` = pixels[i * w + j]
                    val r = ((`val` shr 16 and 0xFF) - imageMean) / imageStd
                    val g = ((`val` shr 8 and 0xFF) - imageMean) / imageStd
                    val b = ((`val` and 0xFF) - imageMean) / imageStd
                    val arr = floatArrayOf(r, g, b)
                    floatValues[i][j] = arr
                }
            }
            return floatValues
        }

        fun l2Normalize(embeddings: Array<FloatArray>, epsilon: Double) {
            for (i in embeddings.indices) {
                var squareSum = 0f
                for (j in embeddings[i].indices) {
                    //  squareSum += embeddings[i][j].pow(2.0) as Float
                    squareSum += embeddings[i][j].toDouble().pow(2.0).toFloat()
                }
                val xInvNorm = sqrt(max(squareSum.toDouble(), epsilon))
                    .toFloat()
                for (j in embeddings[i].indices) {
                    embeddings[i][j] = embeddings[i][j] / xInvNorm
                }
            }
        }
    }
}