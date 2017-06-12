import tensorflow as tf
import numpy as np


def run():
    filename_queue = tf.train.string_input_producer(["trainData.csv"])
    reader = tf.TextLineReader(skip_header_lines=1)
    key, value = reader.read(filename_queue)

    record_defaults = [[1.0], [1.0], [1.0], [1.0], [1.0], [1.0]]
    col1, col2, col3, col4, col5, col6 = tf.decode_csv(value, record_defaults=record_defaults)

    # sample size
    total = 11180
    train_size = 11180 # np.int(total * 0.8 / 10) * 10
    test_size = 560 # total - train_size
    # number of inputs and output
    in_count = 1
    out_count = 1
    batch_size = 20
    # input X
    X = tf.placeholder(tf.float32, [None, in_count])
    # correct answers will go here
    Y_ = tf.placeholder(tf.float32, [None, out_count])
    # for linear regression
    xi = []
    yi = []
    xiyi = []
    xi2 = []
    # feed data in batch
    batch_input = []
    batch_output = []
    # Probability of keeping a node during dropout = 1.0 at test time (no dropout) and 0.75 at training time
    lr = tf.placeholder(tf.float32)
    pkeep = tf.placeholder(tf.float32)
    # weights
    W1 = tf.Variable(tf.truncated_normal([in_count, out_count], stddev=1))
    # biases
    B1 = tf.Variable(tf.ones([out_count]) / 10)
    # the model
    activation = tf.nn.tanh
    YY = activation(tf.matmul(X, W1) + B1)

    # loss function: difference = (predicted_distance - read_distance)^2
    #  where YY: the computed output vector
    #        Y_: the desired output vector
    difference = -tf.log(1 - tf.reduce_sum(tf.abs(YY - Y_)) / batch_size)

    # training, learning rate = 0.05
    train_step = tf.train.GradientDescentOptimizer(lr).minimize(difference)

    with tf.Session() as sess:
        tf.global_variables_initializer().run()

        coord = tf.train.Coordinator()
        threads = tf.train.start_queue_runners(coord=coord)

        idx = 0
        for i in range(train_size):
            x, y, rela_head, beacon_head, pitch, rssi = sess.run([col1, col2, col3, col4, col5, col6])

            if (np.sqrt(np.square(x) + np.square(y)) / 100 >= 1) and (np.sqrt(np.square(x) + np.square(y)) / 100 <= 7.5):
                xi.append(np.log10(np.sqrt(np.square(x) + np.square(y))))
                yi.append(rssi)
                xiyi.append(xi[idx] * yi[idx])
                xi2.append(np.square(xi[idx]))
                idx += 1

                batch_input.append((rssi + 60) / 30)
                batch_output.append(np.sqrt(np.square(x) + np.square(y)) / 1000)

            max_learning_rate = 0.1
            min_learning_rate = 0.001
            decay_speed = 10000.0
            learning_rate = min_learning_rate + (max_learning_rate - min_learning_rate) * np.exp(-i / decay_speed)
            # learning_rate = 0.04

            if idx % batch_size == 0 and len(batch_input):
                train_data = {X: np.reshape(np.array(batch_input), [batch_size, in_count]),
                              Y_: np.reshape(np.array(batch_output), [batch_size, out_count]),
                              lr: learning_rate,
                              pkeep: 1.0}

                # train
                sess.run(train_step, feed_dict=train_data)

                yy, y_ = sess.run([YY, Y_], feed_dict=train_data)
                print(y_[0] * 10, yy[0] * 10, np.sum(np.abs(yy - y_)) * 10 / batch_size)

                batch_input.clear()
                batch_output.clear()

        b = (np.sum(xiyi) - np.sum(xi) * np.sum(yi) / len(xi)) / (np.sum(xi2) - np.square(np.sum(xi)) / len(xi))
        a = np.mean(yi) - b * np.mean(xi)

        print('a:', a, 'b:', b)
        error_nn = 0
        error_dr = 0
        count = 0

        for i in range(test_size):
            x, y, rela_head, beacon_head, pitch, rssi = sess.run([col1, col2, col3, col4, col5, col6])

            if (np.sqrt(np.square(x) + np.square(y)) / 100 >= 1) and (np.sqrt(np.square(x) + np.square(y)) / 100 <= 7.5):
                test_data = {X: np.reshape([(rssi + 60) / 30],
                                           [-1, in_count]),
                             Y_: np.reshape(
                                 [np.sqrt(np.square(x) + np.square(y)) / 1000],
                                 [-1, out_count]),
                             pkeep: 1.0}

                ratio = 0.225

                # test
                y_, yy = sess.run([Y_, YY], feed_dict=test_data)
                dr_result = np.power(10, (rssi - a) / b) / 100
                nn_result = yy[0][0] * 10 * (1 - ratio) + np.power(10, (rssi - a) / b) / 100 * ratio
                real_dist = y_ * 10
                error_dr += np.abs(dr_result - real_dist)
                error_nn += np.abs(nn_result - real_dist)

                if np.abs(nn_result - real_dist) > np.abs(dr_result - real_dist) and np.abs(nn_result - real_dist) > 1.5:
                    count += 1

        print('nn:', error_nn / test_size, 'dr:', error_dr / test_size)
        print('worse rate:', count / test_size * 100, '%')
        print(W1.eval()[0][0])
        print(B1.eval()[0])

        coord.request_stop()
        coord.join(threads)
