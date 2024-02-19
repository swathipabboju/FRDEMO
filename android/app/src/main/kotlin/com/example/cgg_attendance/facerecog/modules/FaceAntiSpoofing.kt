package com.example.cgg_attendance.facerecog.modules

import android.content.res.AssetManager
import android.graphics.Bitmap
import org.tensorflow.lite.Interpreter

import java.io.FileInputStream
import java.nio.MappedByteBuffer
import java.nio.channels.FileChannel
import kotlin.math.abs

class FaceAntiSpoofing(assetManager: AssetManager) {
    private val interpreter: Interpreter

    init {
        val options = Interpreter.Options()
        options.numThreads = 4
        interpreter = Interpreter(loadModelFile(assetManager), options)
    }

    private fun loadModelFile(assetManager: AssetManager): MappedByteBuffer {
        val fileDescriptor = assetManager.openFd(MODEL_FILE)
        val inputStream = FileInputStream(fileDescriptor.fileDescriptor)
        val fileChannel = inputStream.channel
        val startOffset = fileDescriptor.startOffset
        val declaredLength = fileDescriptor.declaredLength
        return fileChannel.map(FileChannel.MapMode.READ_ONLY, startOffset, declaredLength)
    }



    fun antiSpoofing(bitmap: Bitmap?): Float {
        //Resize the face to 256X256, because the shape of the placeholder required for feed data below is (1, 256, 256, 3)
        val bitmapScale =
            Bitmap.createScaledBitmap(bitmap!!, INPUT_IMAGE_SIZE, INPUT_IMAGE_SIZE, true)
        val img = normalizeImage(bitmapScale)
        val input: Array<Array<Array<FloatArray>>?> = arrayOfNulls(1)
        input[0] = img
        val preimage = Array(1) { FloatArray(8) }
        val postimage = Array(1) { FloatArray(8) }
        val outputs: MutableMap<Int, Any> = HashMap()
        outputs[interpreter.getOutputIndex("Identity")] = preimage
        outputs[interpreter.getOutputIndex("Identity_1")] = postimage
        interpreter.runForMultipleInputsOutputs(arrayOf<Any>(input), outputs)
        return leafscore(preimage, postimage)
    }

    fun laplacian(bitmap: Bitmap?): Int {
        //Resize the face to 256X256, because the shape of the placeholder required for feed data below is (1, 256, 256, 3)
        val bitmapScale =
            Bitmap.createScaledBitmap(bitmap!!, INPUT_IMAGE_SIZE, INPUT_IMAGE_SIZE, true)
        val laplace = arrayOf(intArrayOf(0, 1, 0), intArrayOf(1, -4, 1), intArrayOf(0, 1, 0))
        val size = laplace.size
        val img = convertGreyImg(bitmapScale)
        val height = img.size
        val width = img[0].size
        var score = 0
        for (x in 0 until height - size + 1) {
            for (y in 0 until width - size + 1) {
                var result = 0
                // Perform convolution operation on size*size area
                for (i in 0 until size) {
                    for (j in 0 until size) {
                        result += (img[x + i][y + j] and 0xFF) * laplace[i][j]
                    }
                }
                if (result > LAPLACE_THRESHOLD) {
                    score++
                }
            }
        }
        return score
    }



    // Placeholder method to get the focal length of the camera


    companion object {
        private const val MODEL_FILE = "FaceAntiSpoofing.tflite"
        const val INPUT_IMAGE_SIZE =
            256 // The image width and height of the placeholder that requires feed data
        const val THRESHOLD =
            0.8f // Set a threshold value. A value greater than this value is considered an attack.
        const val LAPLACE_THRESHOLD = 50 // Laplacian sampling threshold
        const val LAPLACIAN_THRESHOLD = 300  // Image clarity judgment threshold
        fun normalizeImage(bitmap: Bitmap): Array<Array<FloatArray>> {
            val h = bitmap.height
            val w = bitmap.width
            val floatValues = Array(h) { Array(w) { FloatArray(3) } }
            val imageStd = 255f
            val pixels = IntArray(h * w)
            bitmap.getPixels(pixels, 0, bitmap.width, 0, 0, w, h)
            for (i in 0 until h) { // Note that the height is first and then the width
                for (j in 0 until w) {
                    val `val` = pixels[i * w + j]
                    val r = (`val` shr 16 and 0xFF) / imageStd
                    val g = (`val` shr 8 and 0xFF) / imageStd
                    val b = (`val` and 0xFF) / imageStd
                    val arr = floatArrayOf(r, g, b)
                    floatValues[i][j] = arr
                }
            }
            return floatValues
        }

        private fun leafscore(
            preimage: Array<FloatArray>,
            postimage: Array<FloatArray>
        ): Float {
            var score = 0f
            for (i in 0..7) {
                score += (abs(preimage[0][i].toDouble()) * postimage[0][i]).toFloat()
            }
            return score
        }
    }

    private fun convertGreyImg(bitmap: Bitmap): Array<IntArray> {
        val w = bitmap.width
        val h = bitmap.height
        val pixels = IntArray(h * w)
        bitmap.getPixels(pixels, 0, w, 0, 0, w, h)
        val result = Array(h) {
            IntArray(w)
        }
        val alpha = 0xFF shl 24
        for (i in 0 until h) {
            for (j in 0 until w) {
                val `val` = pixels[w * i + j]
                val red = `val` shr 16 and 0xFF
                val green = `val` shr 8 and 0xFF
                val blue = `val` and 0xFF
                var grey =
                    (red.toFloat() * 0.3 + green.toFloat() * 0.59 + blue.toFloat() * 0.11).toInt()
                grey = alpha or (grey shl 16) or (grey shl 8) or grey
                result[i][j] = grey
            }
        }
        return result
    }
}