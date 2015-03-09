# Outline of the Hidden Markov Model Intro

## Need to explain the following topics

1. Conditional Probability, do I need to explain or just link to the Setosa example?

----

2. Finite State Automata (FSA)

3. Markov Chains

  a. Combining conditional probability with an FSA: the transition probabilities

  b. The Markov assumption and 'first-order' Markov chains

  c. Initial and Accepting States vs. Initial probability distributions

    a. Values of all outgoing arcs from a state must sum to 1

4. FSA Transducers / Simplest Sequence Labelers

5. Hidden Markov Model

  a. Understanding hidden (or latent variables)

  b. Adding in emission (or output) probabilities

  c. Applications

    ### Problem 1: Likelihood, calculated with The Forward Algorithm

    Given an HMM lambda = (A,B)
    And an observation sequence O
    ---
    Determine the likelihood of P(O|lambda)

    lambda(A,B) and O -> P(O|lambda)

    ### Problem 2: Decoding

    Given an observation sequence O
    And an HMM lambda = (A,B)
    ---
    Discover the best hidden state sequence Q

    lambda(A,B) and O -> Q

    ### Problem 3: Learning

    Given an observation sequence O
    And the set of states in the HMM
    ---
    Learn the HMM parameters A and B

    O and Q -> lambda(A,B)


    i. Probability of an observed sequence

    ii. Probability of the latent variables

    iii.

  d. Ergodic (fully connected) vs. Bakis (left-to-right) HMMs


## Visualization ideas

Conditional probability explained as shelves? Probably just link Setosa, do not see how I can improve on it atm.

Box (the hidden state) outputs balls of various colors (the visible ouputs) when the user clicks. Build intuition about the latent variable.


## J&M Thoughts

Frequency counts to compute the probability of the next letter in a sequence would be a vowel. A. A. Markov.

Markov Assumption: the probability of the current state only depends on the previous state.

Output observations depends only on the state that produced it, not any other observation.


